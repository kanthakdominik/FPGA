-- SPI master (20.02): słowa N-bitowe od najstarszego bitu, tryb CPOL/CPHA w czasie pracy,
-- SCLK = f_clk / (2·DIV). dalej = '1' zostawia CS aktywne po słowie (transakcja wielosłowowa).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_master is
  generic (
    N   : positive := 8;
    DIV : positive := 4
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    cpol    : in  std_logic;
    cpha    : in  std_logic;
    start   : in  std_logic;
    dalej   : in  std_logic;
    tx_dane : in  std_logic_vector(N - 1 downto 0);
    rx_dane : out std_logic_vector(N - 1 downto 0);
    zajety  : out std_logic;
    gotowe  : out std_logic := '0';
    sclk    : out std_logic := '0';
    mosi    : out std_logic;
    miso    : in  std_logic;
    cs_n    : out std_logic := '1'
  );
end entity spi_master;

architecture rtl of spi_master is
  type stan_t is (S_SPOCZ, S_CS, S_ZBOCZA, S_KONIEC, S_CZEKA, S_CS_WYS);
  signal stan         : stan_t := S_SPOCZ;
  signal t            : natural range 0 to DIV - 1 := 0;
  signal k            : natural range 0 to 2 * N := 0;   -- zbocza wykonane w słowie
  signal sr_tx, sr_rx : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal trzymaj      : std_logic := '0';
  signal sclk_r       : std_logic := '0';
begin
  mosi   <= sr_tx(N - 1);
  zajety <= '0' when stan = S_SPOCZ or stan = S_CZEKA else '1';
  sclk   <= sclk_r;

  process (clk)
    variable wiodace : boolean;
  begin
    if rising_edge(clk) then
      gotowe <= '0';
      if rst = '1' then
        stan   <= S_SPOCZ;
        cs_n   <= '1';
        sclk_r <= cpol;
      else
        case stan is
          when S_SPOCZ | S_CZEKA =>
            sclk_r <= cpol;
            if start = '1' then
              sr_tx   <= tx_dane;
              trzymaj <= dalej;
              k       <= 0;
              t       <= DIV - 1;
              cs_n    <= '0';
              stan    <= S_CS when stan = S_SPOCZ else S_ZBOCZA;
            end if;
          when S_CS =>
            if t = 0 then
              t    <= DIV - 1;
              stan <= S_ZBOCZA;
            else
              t <= t - 1;
            end if;
          when S_ZBOCZA =>
            if t = 0 then
              t       <= DIV - 1;
              k       <= k + 1;
              sclk_r  <= not sclk_r;
              wiodace := (k mod 2 = 0);                       -- następne zbocze nieparzyste
              -- próbkowanie: CPHA = 0 na wiodących, CPHA = 1 na końcowych
              if wiodace xor (cpha = '1') then
                sr_rx <= sr_rx(N - 2 downto 0) & miso;
              elsif k /= 0 and k /= 2 * N - 1 then
                sr_tx <= sr_tx(N - 2 downto 0) & '0';           -- wystawienie kolejnego bitu
              end if;
              if k = 2 * N - 1 then stan <= S_KONIEC; end if;
            else
              t <= t - 1;
            end if;
          when S_KONIEC =>
            if t = 0 then
              rx_dane <= sr_rx;
              gotowe  <= '1';
              t       <= DIV - 1;
              if trzymaj = '1' then
                stan <= S_CZEKA;
              else
                cs_n <= '1';
                stan <= S_CS_WYS;
              end if;
            else
              t <= t - 1;
            end if;
          when S_CS_WYS =>
            if t = 0 then stan <= S_SPOCZ; else t <= t - 1; end if;
        end case;
      end if;
    end if;
  end process;
end architecture rtl;
