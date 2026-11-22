-- Zadanie 1: detektor zbocza narastającego i opadającego (d synchroniczne z clk). Wyjścia kombinacyjne.
library ieee;
use ieee.std_logic_1164.all;

entity edge_detect is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    d    : in  std_logic;
    rise : out std_logic;
    fall : out std_logic
  );
end entity;

architecture rtl of edge_detect is
  signal d_q : std_logic := '0';        -- wartość d z poprzedniego taktu
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then d_q <= '0'; else d_q <= d; end if;
    end if;
  end process;

  rise <= d and not d_q;
  fall <= not d and d_q;
end architecture;
