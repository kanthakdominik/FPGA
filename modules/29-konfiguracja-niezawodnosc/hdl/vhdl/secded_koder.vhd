-- Koder SECDED (39,32) (29.04).
library ieee;
use ieee.std_logic_1164.all;
use work.secded_pkg.all;

entity secded_koder is
  port (
    d : in  std_logic_vector(31 downto 0);
    c : out std_logic_vector(38 downto 0)
  );
end entity secded_koder;

architecture rtl of secded_koder is
begin
  c <= koduj(d);
end architecture rtl;
