-- Projekt 6 (31.06): mikrokontroler na rdzeniu rv_potok — pamięć, GPIO, licznik z porównaniem, UART,
-- TOHOST i pwm_avl. Mapa adresów jak w wersji Verilog. Zawartość RAM: PLIK (textio — symulacja) albo
-- PLIK_MIF (atrybut ram_init_file — Quartus).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity rv_mcu is
  generic (
    SLOWA    : positive := 1024;
    PLIK     : string   := "";
    PLIK_MIF : string   := "";
    CLK_HZ   : positive := 50_000_000;
    BAUD     : positive := 115_200
  );
  port (
    clk, rst : in  std_logic;
    wej      : in  std_logic_vector(31 downto 0);
    led      : out std_logic_vector(31 downto 0) := (others => '0');
    uart_rx  : in  std_logic;
    uart_tx  : out std_logic;
    pwm_wy   : out std_logic;
    koniec   : out std_logic := '0';
    wycofana : out std_logic
  );
end entity rv_mcu;

architecture rtl of rv_mcu is
  type pam_t is array (0 to SLOWA - 1) of std_logic_vector(31 downto 0);

  impure function wczytaj(nazwa : string) return pam_t is
    file f      : text;
    variable st : file_open_status;
    variable l  : line;
    variable v  : std_logic_vector(31 downto 0);
    variable r  : pam_t := (others => (others => '0'));
  begin
    if nazwa'length = 0 then
      return r;
    end if;
    file_open(st, f, nazwa, read_mode);
    assert st = open_ok report "rv_mcu: nie mozna otworzyc " & nazwa severity failure;
    for i in pam_t'range loop
      exit when endfile(f);
      readline(f, l);
      hread(l, v);
      r(i) := v;
    end loop;
    file_close(f);
    return r;
  end function;

  signal pam : pam_t := wczytaj(PLIK);
  attribute ram_init_file : string;
  attribute ram_init_file of pam : signal is PLIK_MIF;

  signal i_adr, d_adr, d_wdane, d_rdane : std_logic_vector(31 downto 0);
  signal i_dane, d_ram, io_rd, pwm_rd   : std_logic_vector(31 downto 0) := (others => '0');
  signal d_wstrb                        : std_logic_vector(3 downto 0);
  signal d_odczyt                       : std_logic;
  signal ram_sel, pwm_sel, sys_sel, zapis : std_logic;
  signal ram_w, pwm_w                   : std_logic := '0';
  signal pwm_zap, pwm_odcz              : std_logic;
  signal ia, da                         : natural range 0 to SLOWA - 1;
  signal rx_dane                        : std_logic_vector(7 downto 0);
  signal rx_wazne, tx_gotowy, tx_wolny  : std_logic;
  signal tx_start, tx_start_d, rx_jest, rx_przep, flaga : std_logic := '0';
  signal tx_bajt, rx_bufor              : std_logic_vector(7 downto 0) := (others => '0');
  signal licznik                        : unsigned(31 downto 0) := (others => '0');
  signal porown                         : unsigned(31 downto 0) := (others => '1');
  signal rej                            : natural range 0 to 63;
begin
  u_cpu : entity work.rv_potok port map (
    clk => clk, rst => rst, i_adr => i_adr, i_dane => i_dane, d_adr => d_adr, d_wdane => d_wdane,
    d_wstrb => d_wstrb, d_odczyt => d_odczyt, d_rdane => d_rdane, wycofana => wycofana);

  ia      <= to_integer(unsigned(i_adr(31 downto 2))) mod SLOWA;
  da      <= to_integer(unsigned(d_adr(31 downto 2))) mod SLOWA;
  ram_sel <= '1' when d_adr(31 downto 28) = x"0" else '0';
  pwm_sel <= '1' when d_adr(31 downto 28) = x"1" and d_adr(8) = '1' else '0';
  sys_sel <= '1' when d_adr(31 downto 28) = x"1" and d_adr(8) = '0' else '0';
  zapis   <= '0' when d_wstrb = "0000" else '1';
  rej     <= to_integer(unsigned(d_adr(7 downto 2)));

  process (clk)
  begin
    if rising_edge(clk) then
      i_dane <= pam(ia);
    end if;
  end process;
  process (clk)
  begin
    if rising_edge(clk) then
      if ram_sel = '1' then
        for b in 0 to 3 loop
          if d_wstrb(b) = '1' then pam(da)(8 * b + 7 downto 8 * b) <= d_wdane(8 * b + 7 downto 8 * b); end if;
        end loop;
      end if;
      d_ram <= pam(da);
    end if;
  end process;

  u_rx : entity work.uart_rx generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
    port map (clk => clk, rst => rst, rx => uart_rx, dane => rx_dane, wazne => rx_wazne, blad_ramki => open,
              blad_parz => open);
  u_tx : entity work.uart_tx generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
    port map (clk => clk, rst => rst, start => tx_start, dane => tx_bajt, gotowy => tx_gotowy, tx => uart_tx);
  tx_wolny <= tx_gotowy and not tx_start and not tx_start_d;

  process (clk)
  begin
    if rising_edge(clk) then
      koniec <= '0';
      tx_start <= '0';
      tx_start_d <= tx_start;
      if rst = '1' then
        led <= (others => '0'); licznik <= (others => '0'); porown <= (others => '1'); flaga <= '0';
        rx_jest <= '0'; rx_przep <= '0';
      else
        licznik <= licznik + 1;
        if licznik = porown then flaga <= '1'; end if;
        if rx_wazne = '1' then
          if rx_jest = '1' then rx_przep <= '1'; end if;
          rx_bufor <= rx_dane;
          rx_jest <= '1';
        end if;
        if sys_sel = '1' and zapis = '1' then
          case rej is
            when 0 => led <= d_wdane;
            when 2 => porown <= unsigned(d_wdane);
            when 3 => if d_wdane(0) = '1' then flaga <= '0'; end if;
            when 4 => if tx_wolny = '1' then tx_bajt <= d_wdane(7 downto 0); tx_start <= '1'; end if;
            when 5 => if d_wdane(2) = '1' then rx_przep <= '0'; end if;
            when 6 => koniec <= '1';
            when others => null;
          end case;
        end if;
        if sys_sel = '1' and d_odczyt = '1' and rej = 4 and rx_wazne = '0' then rx_jest <= '0'; end if;
      end if;
      if d_odczyt = '1' then
        case rej is
          when 0 => io_rd <= wej;
          when 1 => io_rd <= std_logic_vector(licznik);
          when 2 => io_rd <= std_logic_vector(porown);
          when 3 => io_rd <= (31 downto 1 => '0') & flaga;
          when 4 => io_rd <= x"000000" & rx_bufor;
          when 5 => io_rd <= (31 downto 3 => '0') & rx_przep & rx_jest & tx_wolny;
          when others => io_rd <= (others => '0');
        end case;
      end if;
    end if;
  end process;

  pwm_zap  <= pwm_sel and zapis;
  pwm_odcz <= d_odczyt and pwm_sel;
  u_pwm : entity work.pwm_avl port map (
    clk => clk, rst => rst, address => d_adr(3 downto 2), read => pwm_odcz, write => pwm_zap,
    writedata => d_wdane, readdata => pwm_rd, irq => open, pwm => pwm_wy);

  process (clk)
  begin
    if rising_edge(clk) then
      ram_w <= ram_sel;
      pwm_w <= pwm_sel;
    end if;
  end process;
  d_rdane <= d_ram when ram_w = '1' else pwm_rd when pwm_w = '1' else io_rd;
end architecture rtl;
