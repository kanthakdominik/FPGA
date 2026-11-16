-- Wybór jednej z dwóch sum: y = a + b albo a + c.
-- Opis "dwa sumatory, potem multiplekser" — syntezator może (ale nie musi) zamienić go na jeden sumator.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addsel_two_adders is
  generic (W : positive := 16);
  port (
    sel     : in  std_logic;
    a, b, c : in  std_logic_vector(W - 1 downto 0);
    y       : out std_logic_vector(W downto 0)
  );
end entity addsel_two_adders;

architecture rtl of addsel_two_adders is
  signal sum_ab, sum_ac : unsigned(W downto 0);
begin
  sum_ab <= resize(unsigned(a), W + 1) + resize(unsigned(b), W + 1);
  sum_ac <= resize(unsigned(a), W + 1) + resize(unsigned(c), W + 1);
  y      <= std_logic_vector(sum_ac) when sel = '1' else std_logic_vector(sum_ab);
end architecture rtl;
