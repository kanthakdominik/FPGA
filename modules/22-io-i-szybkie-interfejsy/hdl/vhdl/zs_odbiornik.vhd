-- Odbiornik źródłowo-synchroniczny (22.02): rejestr DDR taktowany odebranym zegarem (osobna domena).
library ieee;
use ieee.std_logic_1164.all;

entity zs_odbiornik is
  port (
    rx_clk : in  std_logic;
    rx_d   : in  std_logic;
    dane   : out std_logic_vector(1 downto 0)              -- dane(1) - bit odebrany pierwszy
  );
end entity zs_odbiornik;

architecture rtl of zs_odbiornik is
begin
  u_dane : entity work.ddr_wej port map (clk => rx_clk, d => rx_d, q_h => dane(1), q_l => dane(0));
end architecture rtl;
