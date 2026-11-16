-- Mnożarka liczb bez znaku: iloczyn ma 2*W bitów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mult is
  generic (W : positive := 8);
  port (
    a, b : in  std_logic_vector(W - 1 downto 0);
    p    : out std_logic_vector(2 * W - 1 downto 0)
  );
end entity mult;

architecture rtl of mult is
begin
  p <= std_logic_vector(unsigned(a) * unsigned(b));
end architecture rtl;
