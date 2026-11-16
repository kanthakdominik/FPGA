-- Ta sama funkcja co addsel_two_adders, opisana jako "multiplekser, potem jeden sumator".
-- Gwarantuje jeden sumator niezależnie od tego, czy syntezator dzieli zasoby.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addsel_one_adder is
  generic (W : positive := 16);
  port (
    sel     : in  std_logic;
    a, b, c : in  std_logic_vector(W - 1 downto 0);
    y       : out std_logic_vector(W downto 0)
  );
end entity addsel_one_adder;

architecture rtl of addsel_one_adder is
  signal operand : std_logic_vector(W - 1 downto 0);
begin
  operand <= c when sel = '1' else b;
  y       <= std_logic_vector(resize(unsigned(a), W + 1) + resize(unsigned(operand), W + 1));
end architecture rtl;
