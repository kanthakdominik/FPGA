-- Kontroler pamięci SPI/QSPI flash (23.03), tryb SPI 0: rozkaz (8 bitów na DQ0) [+ adres 24 bity] [+ cykle
-- puste] [+ dane 1-1-1 (zapis DQ0, odczyt DQ1) albo 1-1-4 (4 bity na cykl)]. SCLK = f_clk / (2·DIV).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity qspi_master is
  generic (DIV : positive := 2);
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    start     : in  std_logic;
    rozkaz    : in  std_logic_vector(7 downto 0);
    adres     : in  std_logic_vector(23 downto 0);
    z_adresem : in  std_logic;
    puste     : in  std_logic_vector(3 downto 0);
    dlugosc   : in  std_logic_vector(8 downto 0);
    zapis     : in  std_logic;
    quad      : in  std_logic;
    wdane     : in  std_logic_vector(7 downto 0);
    wpobierz  : out std_logic := '0';
    rdane     : out std_logic_vector(7 downto 0);
    rwazne    : out std_logic := '0';
    gotowy    : out std_logic := '1';
    sclk      : out std_logic := '0';
    cs_n      : out std_logic := '1';
    dq_o      : out std_logic_vector(3 downto 0) := "0000";
    dq_oe     : out std_logic_vector(3 downto 0) := "0000";
    dq_i      : in  std_logic_vector(3 downto 0)
  );
end entity qspi_master;

architecture rtl of qspi_master is
  type stan_t is (S_SPOCZ, S_PRACA, S_KONIEC, S_CS);
  type faza_t is (F_ROZ, F_PUSTE, F_DANE);
  signal stan    : stan_t := S_SPOCZ;
  signal faza    : faza_t := F_ROZ;
  signal t       : natural range 0 to DIV - 1 := 0;
  signal licz    : unsigned(11 downto 0) := (others => '0');
  signal sr      : std_logic_vector(31 downto 0) := (others => '0');
  signal wsr, rsr : std_logic_vector(7 downto 0) := (others => '0');
  signal bw, br  : unsigned(2 downto 0) := "000";
  signal r_puste : unsigned(3 downto 0) := "0000";
  signal r_dl    : unsigned(8 downto 0) := (others => '0');
  signal r_zapis, r_quad, sc : std_logic := '0';
  signal ost_b   : unsigned(2 downto 0);
begin
  sclk  <= sc;
  ost_b <= "001" when r_quad = '1' else "111";

  process (clk)
    variable nr : std_logic_vector(7 downto 0);
  begin
    if rising_edge(clk) then
      wpobierz <= '0';
      rwazne   <= '0';
      if rst = '1' then
        stan   <= S_SPOCZ;
        sc     <= '0';
        cs_n   <= '1';
        dq_oe  <= "0000";
        dq_o   <= "0000";
        gotowy <= '1';
      else
        case stan is
          when S_SPOCZ =>
            if start = '1' then
              gotowy  <= '0';
              cs_n    <= '0';
              stan    <= S_PRACA;
              faza    <= F_ROZ;
              t       <= DIV - 1;
              sr      <= rozkaz & adres;
              licz    <= to_unsigned(31, 12) when z_adresem = '1' else to_unsigned(7, 12);
              dq_oe   <= "0001";
              dq_o    <= "000" & rozkaz(7);
              r_puste <= unsigned(puste);
              r_dl    <= unsigned(dlugosc);
              r_zapis <= zapis;
              r_quad  <= quad;
            end if;
          when S_PRACA =>
            if t /= 0 then
              t <= t - 1;
            else
              t  <= DIV - 1;
              sc <= not sc;
              if sc = '0' then                                   -- zbocze narastające: próbkowanie
                if faza = F_DANE and r_zapis = '0' then
                  if r_quad = '1' then nr := rsr(3 downto 0) & dq_i; else nr := rsr(6 downto 0) & dq_i(1); end if;
                  rsr <= nr;
                  if br = ost_b then
                    br     <= "000";
                    rdane  <= nr;
                    rwazne <= '1';
                  else
                    br <= br + 1;
                  end if;
                end if;
              else                                               -- zbocze opadające: następny cykl
                if licz /= 0 then
                  licz <= licz - 1;
                  if faza = F_ROZ then
                    sr   <= sr(30 downto 0) & '0';
                    dq_o <= "000" & sr(30);
                  elsif faza = F_DANE and r_zapis = '1' then
                    if bw = ost_b then                           -- następny bajt
                      bw       <= "000";
                      wsr      <= wdane;
                      wpobierz <= '1';
                      if r_quad = '1' then dq_o <= wdane(7 downto 4); else dq_o <= "000" & wdane(7); end if;
                    else
                      bw <= bw + 1;
                      if r_quad = '1' then
                        wsr  <= wsr(3 downto 0) & "0000";
                        dq_o <= wsr(3 downto 0);
                      else
                        wsr  <= wsr(6 downto 0) & '0';
                        dq_o <= "000" & wsr(6);
                      end if;
                    end if;
                  end if;
                elsif faza = F_DANE then
                  stan <= S_KONIEC;
                elsif faza = F_ROZ and r_puste /= 0 then         -- następna faza: cykle puste
                  faza  <= F_PUSTE;
                  licz  <= resize(r_puste, 12) - 1;
                  dq_oe <= "0000";
                elsif r_dl /= 0 then                             -- następna faza: dane
                  faza <= F_DANE;
                  bw   <= "000";
                  br   <= "000";
                  if r_quad = '1' then licz <= resize(r_dl & '0', 12) - 1;
                  else licz <= resize(r_dl & "000", 12) - 1; end if;
                  if r_zapis = '1' then
                    wsr      <= wdane;
                    wpobierz <= '1';
                    if r_quad = '1' then
                      dq_oe <= "1111";
                      dq_o  <= wdane(7 downto 4);
                    else
                      dq_oe <= "0001";
                      dq_o  <= "000" & wdane(7);
                    end if;
                  else
                    dq_oe <= "0000";
                  end if;
                else
                  stan <= S_KONIEC;
                end if;
              end if;
            end if;
          when S_KONIEC =>
            if t /= 0 then
              t <= t - 1;
            else
              cs_n  <= '1';
              dq_oe <= "0000";
              t     <= DIV - 1;
              stan  <= S_CS;
            end if;
          when S_CS =>
            if t /= 0 then
              t <= t - 1;
            else
              gotowy <= '1';
              stan   <= S_SPOCZ;
            end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
