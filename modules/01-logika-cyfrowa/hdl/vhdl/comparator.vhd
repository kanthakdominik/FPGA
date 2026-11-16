-- Komparator liczb bez znaku: równe, mniejsze, większe.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator is
  generic (W : positive := 8);
  port (
    a, b       : in  std_logic_vector(W - 1 downto 0);
    eq, lt, gt : out std_logic
  );
end entity comparator;

architecture rtl of comparator is
begin
  eq <= '1' when unsigned(a) = unsigned(b) else '0';
  lt <= '1' when unsigned(a) < unsigned(b) else '0';
  gt <= '1' when unsigned(a) > unsigned(b) else '0';
end architecture rtl;
