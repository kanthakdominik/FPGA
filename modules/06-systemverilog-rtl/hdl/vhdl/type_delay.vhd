-- Linia opóźniająca parametryzowana typem (VHDL-2008: generic type).
-- Nie wszystkie narzędzia syntezy to obsługują — zob. temat 06.07.
library ieee;
use ieee.std_logic_1164.all;

entity type_delay is
  generic (
    type T;                                     -- dowolny typ: wektor, rekord
    DEPTH : positive := 2
  );
  port (
    clk : in  std_logic;
    d   : in  T;
    q   : out T
  );
end entity type_delay;

architecture rtl of type_delay is
  type stage_t is array (0 to DEPTH - 1) of T;
  signal stage : stage_t;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      stage(0) <= d;
      for i in 1 to DEPTH - 1 loop
        stage(i) <= stage(i - 1);
      end loop;
    end if;
  end process;

  q <= stage(DEPTH - 1);
end architecture rtl;
