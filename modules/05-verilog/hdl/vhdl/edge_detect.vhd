-- Detektor zboczy sygnału synchronicznego: impuls jednego taktu przy zmianie wejścia.
library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
  port (
    clk  : in  std_logic;
    d    : in  std_logic;                       -- zsynchronizowane z clk
    rise : out std_logic;
    fall : out std_logic;
    any  : out std_logic
  );
end entity edge_detect;

architecture rtl of edge_detect is
  signal d_q : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      d_q <= d;
    end if;
  end process;

  rise <= d and not d_q;
  fall <= not d and d_q;
  any  <= d xor d_q;
end architecture rtl;
