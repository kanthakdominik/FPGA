-- Średnia dwóch liczb ze znakiem zaokrąglona w dół: y = floor((a + b) / 2).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity avg_signed is
  generic (W : positive := 8);
  port (
    a, b : in  std_logic_vector(W - 1 downto 0);
    y    : out std_logic_vector(W - 1 downto 0)
  );
end entity avg_signed;

architecture rtl of avg_signed is
  signal sum, half : signed(W downto 0);
begin
  sum  <= resize(signed(a), W + 1) + resize(signed(b), W + 1);
  half <= shift_right(sum, 1);                 -- dla signed: przesunięcie arytmetyczne
  y    <= std_logic_vector(half(W - 1 downto 0));
end architecture rtl;
