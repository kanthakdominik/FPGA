-- Nadajnik źródłowo-synchroniczny (22.02): 2 bity na takt przez rejestr DDR i zegar przesyłany obok danych
-- tym samym rodzajem rejestru (d_h = '1', d_l = '0').
library ieee;
use ieee.std_logic_1164.all;

entity zs_nadajnik is
  port (
    clk    : in  std_logic;
    dane   : in  std_logic_vector(1 downto 0);             -- dane(1) wychodzi pierwszy
    tx_clk : out std_logic;
    tx_d   : out std_logic
  );
end entity zs_nadajnik;

architecture rtl of zs_nadajnik is
begin
  u_zegar : entity work.ddr_wyj port map (clk => clk, d_h => '1', d_l => '0', q => tx_clk);
  u_dane  : entity work.ddr_wyj port map (clk => clk, d_h => dane(1), d_l => dane(0), q => tx_d);
end architecture rtl;
