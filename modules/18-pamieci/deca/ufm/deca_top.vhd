-- Moduł nadrzędny DECA - VHDL. Licznik naciśnięć zapamiętany w pamięci flash użytkownika (18.05):
-- po starcie odczyt słowa 0 z UFM (x"FFFFFFFF" = skasowane -> 0) na LED(6..0); KEY(1): kasowanie strony,
-- zapis licznika + 1, odczyt kontrolny; KEY(1) przy SW(0) w górze: tylko kasowanie; LED(7): błąd.
-- Rdzeń On-Chip Flash generuje się w Quartusie jako ufm_flash (README.md w tym katalogu); FLASH_AW musi
-- być równe szerokości portu avmm_data_addr wygenerowanego rdzenia (deklaracja komponentu poniżej).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;
    KEY           : in  std_logic_vector(1 downto 0);
    SW            : in  std_logic_vector(1 downto 0);
    LED           : out std_logic_vector(7 downto 0)   -- '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  constant FLASH_AW : positive := 17;

  component ufm_flash
    port (
      clock                   : in  std_logic;
      reset_n                 : in  std_logic;
      avmm_csr_addr           : in  std_logic;
      avmm_csr_read           : in  std_logic;
      avmm_csr_writedata      : in  std_logic_vector(31 downto 0);
      avmm_csr_write          : in  std_logic;
      avmm_csr_readdata       : out std_logic_vector(31 downto 0);
      avmm_data_addr          : in  std_logic_vector(FLASH_AW - 1 downto 0);
      avmm_data_read          : in  std_logic;
      avmm_data_writedata     : in  std_logic_vector(31 downto 0);
      avmm_data_write         : in  std_logic;
      avmm_data_readdata      : out std_logic_vector(31 downto 0);
      avmm_data_waitrequest   : out std_logic;
      avmm_data_readdatavalid : out std_logic;
      avmm_data_burstcount    : in  std_logic_vector(3 downto 0)
    );
  end component;

  type krok_t is (T_START, T_ODCZYT, T_CZEKAJ, T_KASUJ, T_ZAPIS, T_KONTROLA);
  signal clk, rst, rst_n : std_logic;
  signal rs       : std_logic_vector(1 downto 0) := "00";
  signal k_s      : std_logic_vector(2 downto 0) := "111";
  signal sw_s     : std_logic_vector(1 downto 0) := "00";
  signal dz       : unsigned(17 downto 0) := (others => '0');
  signal k_f, k_f_d : std_logic := '1';
  signal nacisniecie : std_logic;
  signal start    : std_logic := '0';
  signal op       : std_logic_vector(1 downto 0) := "00";
  signal wdata, rdata : std_logic_vector(31 downto 0) := (others => '0');
  signal busy, done, ok : std_logic;
  signal csr_addr, csr_read, csr_write, data_read, data_write, waitreq, rdvalid : std_logic;
  signal csr_wd, csr_rd, data_wd, data_rd : std_logic_vector(31 downto 0);
  signal data_addr : std_logic_vector(FLASH_AW - 1 downto 0);
  signal burst    : std_logic_vector(3 downto 0);
  signal t        : krok_t := T_START;
  signal licznik  : unsigned(31 downto 0) := (others => '0');
  signal blad     : std_logic := '0';
begin
  clk <= MAX10_CLK1_50;
  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs <= "00"; elsif rising_edge(clk) then rs <= rs(0) & '1'; end if;
  end process;
  rst   <= not rs(1);
  rst_n <= rs(1);

  -- przycisk i przełącznik: synchronizacja, filtr drgań (co ok. 5 ms), zbocze naciśnięcia
  process (clk)
  begin
    if rising_edge(clk) then
      k_s  <= k_s(1 downto 0) & KEY(1);
      sw_s <= sw_s(0) & SW(0);
      dz   <= dz + 1;
      if dz = 0 then
        k_f <= k_s(2);
      end if;
      k_f_d <= k_f;
    end if;
  end process;
  nacisniecie <= k_f_d and not k_f;

  u_ster : entity work.ufm_sterownik
    generic map (AW => FLASH_AW, SEKTOR => 1, CZEKAJ => 4)
    port map (clk => clk, rst => rst, start => start, op => op, addr => (others => '0'), wdata => wdata,
              busy => busy, done => done, ok => ok, rdata => rdata, csr_addr => csr_addr, csr_read => csr_read,
              csr_write => csr_write, csr_writedata => csr_wd, csr_readdata => csr_rd, data_addr => data_addr,
              data_read => data_read, data_write => data_write, data_writedata => data_wd,
              data_burstcount => burst, data_waitrequest => waitreq, data_readdatavalid => rdvalid,
              data_readdata => data_rd);

  u_flash : ufm_flash
    port map (clock => clk, reset_n => rst_n, avmm_csr_addr => csr_addr, avmm_csr_read => csr_read,
              avmm_csr_writedata => csr_wd, avmm_csr_write => csr_write, avmm_csr_readdata => csr_rd,
              avmm_data_addr => data_addr, avmm_data_read => data_read, avmm_data_writedata => data_wd,
              avmm_data_write => data_write, avmm_data_readdata => data_rd, avmm_data_waitrequest => waitreq,
              avmm_data_readdatavalid => rdvalid, avmm_data_burstcount => burst);

  -- sekwencja: odczyt po starcie; naciśnięcie -> kasowanie, zapis, odczyt kontrolny
  process (clk)
  begin
    if rising_edge(clk) then
      start <= '0';
      if rst = '1' then
        t    <= T_START;
        blad <= '0';
      else
        case t is
          when T_START =>
            op <= "00"; start <= '1'; t <= T_ODCZYT;
          when T_ODCZYT =>
            if done = '1' then
              if rdata = x"FFFFFFFF" then licznik <= (others => '0'); else licznik <= unsigned(rdata); end if;
              if ok = '0' then blad <= '1'; end if;
              t <= T_CZEKAJ;
            end if;
          when T_CZEKAJ =>
            if nacisniecie = '1' and busy = '0' then
              if sw_s(1) = '1' then wdata <= x"FFFFFFFF"; else wdata <= std_logic_vector(licznik + 1); end if;
              op <= "10"; start <= '1'; t <= T_KASUJ;
            end if;
          when T_KASUJ =>
            if done = '1' then
              if ok = '0' then blad <= '1'; end if;
              if sw_s(1) = '1' then
                op <= "00"; start <= '1'; t <= T_ODCZYT;
              else
                op <= "01"; start <= '1'; t <= T_ZAPIS;
              end if;
            end if;
          when T_ZAPIS =>
            if done = '1' then
              if ok = '0' then blad <= '1'; end if;
              op <= "00"; start <= '1'; t <= T_KONTROLA;
            end if;
          when T_KONTROLA =>
            if done = '1' then
              if ok = '0' or rdata /= wdata then blad <= '1'; end if;
              licznik <= unsigned(rdata);
              t <= T_CZEKAJ;
            end if;
        end case;
      end if;
    end if;
  end process;

  LED <= not (blad & std_logic_vector(licznik(6 downto 0)));
end architecture rtl;
