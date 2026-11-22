-- Głosowanie większościowe 2 z 3 (29.04): y = (a and b) or (a and c) or (b and c); niezgodny — różnica kopii.
library ieee;
use ieee.std_logic_1164.all;

entity tmr_glos is
  generic (W : positive := 16);
  port (
    a, b, c   : in  std_logic_vector(W - 1 downto 0);
    y         : out std_logic_vector(W - 1 downto 0);
    niezgodny : out std_logic
  );
end entity tmr_glos;

architecture rtl of tmr_glos is
begin
  y         <= (a and b) or (a and c) or (b and c);
  niezgodny <= '1' when a /= b or a /= c else '0';
end architecture rtl;
