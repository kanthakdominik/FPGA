-- Mały SoC (27.03, 27.07): rdzeń rv_potok, wspólna pamięć programu i danych (SLOWA słów, dwa porty z odczytem
-- synchronicznym, zapis z maską bajtów), rejestry systemowe i pwm_avl (Avalon-MM). Mapa adresów jak w wersji
-- Verilog: RAM od 0, 0x1000_0000 LED/wej, +4 licznik taktów, +8 TOHOST, +C KONSOLA, +10 licznik instrukcji,
-- 0x1000_0100 pwm_avl. Zawartość RAM: PLIK (textio — symulacja) albo PLIK_MIF (atrybut ram_init_file —
-- Quartus, który nie wykonuje textio w syntezie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity rv_soc is
  generic (
    SLOWA    : positive := 256;
    PLIK     : string   := "";
    PLIK_MIF : string   := ""
  );
  port (
    clk, rst   : in  std_logic;
    wej        : in  std_logic_vector(31 downto 0);
    led        : out std_logic_vector(31 downto 0) := (others => '0');
    pwm_wy     : out std_logic;
    pwm_irq    : out std_logic;
    koniec     : out std_logic := '0';
    znak       : out std_logic_vector(7 downto 0) := (others => '0');
    znak_wazny : out std_logic := '0';
    wycofana   : out std_logic;
    mon_adr    : out std_logic_vector(31 downto 0);
    mon_dane   : out std_logic_vector(31 downto 0);
    mon_strb   : out std_logic_vector(3 downto 0)
  );
end entity rv_soc;

architecture rtl of rv_soc is
  type pam_t is array (0 to SLOWA - 1) of std_logic_vector(31 downto 0);

  impure function wczytaj(nazwa : string) return pam_t is
    file f       : text;
    variable st  : file_open_status;
    variable l   : line;
    variable v   : std_logic_vector(31 downto 0);
    variable r   : pam_t := (others => (others => '0'));
  begin
    if nazwa'length = 0 then
      return r;
    end if;
    file_open(st, f, nazwa, read_mode);
    assert st = open_ok report "rv_soc: nie mozna otworzyc " & nazwa severity failure;
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
  signal d_odczyt, wyc                  : std_logic;
  signal ram_sel, pwm_sel, sys_sel      : std_logic;
  signal ram_w, pwm_w                   : std_logic := '0';
  signal pwm_zap, pwm_odcz              : std_logic;
  signal takty, instr                   : unsigned(31 downto 0) := (others => '0');
  signal ia, da                         : natural range 0 to SLOWA - 1;
begin
  u_cpu : entity work.rv_potok port map (
    clk => clk, rst => rst, i_adr => i_adr, i_dane => i_dane, d_adr => d_adr, d_wdane => d_wdane,
    d_wstrb => d_wstrb, d_odczyt => d_odczyt, d_rdane => d_rdane, wycofana => wyc);
  wycofana <= wyc;

  ia      <= to_integer(unsigned(i_adr(31 downto 2))) mod SLOWA;   -- adresy powyżej rozmiaru się powtarzają
  da      <= to_integer(unsigned(d_adr(31 downto 2))) mod SLOWA;
  ram_sel <= '1' when d_adr(31 downto 28) = x"0" else '0';
  pwm_sel <= '1' when d_adr(31 downto 28) = x"1" and d_adr(8) = '1' else '0';
  sys_sel <= '1' when d_adr(31 downto 28) = x"1" and d_adr(8) = '0' else '0';

  -- ---------------------------------------------------------------- pamięć dwuportowa
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
          if d_wstrb(b) = '1' then
            pam(da)(8 * b + 7 downto 8 * b) <= d_wdane(8 * b + 7 downto 8 * b);
          end if;
        end loop;
      end if;
      d_ram <= pam(da);
    end if;
  end process;

  -- ---------------------------------------------------------------- rejestry systemowe
  process (clk)
  begin
    if rising_edge(clk) then
      koniec     <= '0';
      znak_wazny <= '0';
      if rst = '1' then
        led <= (others => '0'); takty <= (others => '0'); instr <= (others => '0'); znak <= (others => '0');
      else
        takty <= takty + 1;
        if wyc = '1' then
          instr <= instr + 1;
        end if;
        if sys_sel = '1' and d_wstrb /= "0000" then
          case to_integer(unsigned(d_adr(7 downto 2))) is
            when 0      => led <= d_wdane;
            when 2      => koniec <= '1';
            when 3      => znak <= d_wdane(7 downto 0); znak_wazny <= '1';
            when others => null;
          end case;
        end if;
      end if;
      if d_odczyt = '1' then
        case to_integer(unsigned(d_adr(7 downto 2))) is
          when 0      => io_rd <= wej;
          when 1      => io_rd <= std_logic_vector(takty);
          when 4      => io_rd <= std_logic_vector(instr);
          when others => io_rd <= (others => '0');
        end case;
      end if;
    end if;
  end process;

  -- ---------------------------------------------------------------- PWM (Avalon-MM, readLatency 1)
  pwm_zap  <= '1' when pwm_sel = '1' and d_wstrb /= "0000" else '0';
  pwm_odcz <= d_odczyt and pwm_sel;
  u_pwm : entity work.pwm_avl port map (
    clk => clk, rst => rst, address => d_adr(3 downto 2), read => pwm_odcz, write => pwm_zap,
    writedata => d_wdane, readdata => pwm_rd, irq => pwm_irq, pwm => pwm_wy);

  process (clk)
  begin
    if rising_edge(clk) then
      ram_w <= ram_sel;
      pwm_w <= pwm_sel;
    end if;
  end process;
  d_rdane <= d_ram when ram_w = '1' else pwm_rd when pwm_w = '1' else io_rd;

  mon_adr  <= d_adr;
  mon_dane <= d_wdane;
  mon_strb <= d_wstrb;
end architecture rtl;
