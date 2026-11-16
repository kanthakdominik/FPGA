-- Dekoder cyfry szesnastkowej na wskaźnik siedmiosegmentowy.
-- seg(6 downto 0) = g f e d c b a, '1' = segment świeci (dla wyświetlacza ze wspólną katodą).
library ieee;
use ieee.std_logic_1164.all;

entity seg7_decoder is
  port (
    hex : in  std_logic_vector(3 downto 0);
    seg : out std_logic_vector(6 downto 0)
  );
end entity seg7_decoder;

architecture rtl of seg7_decoder is
begin
  -- with ... select: przypisanie współbieżne, wszystkie przypadki rozłączne (multiplekser)
  with hex select seg <=
    "0111111" when x"0",
    "0000110" when x"1",
    "1011011" when x"2",
    "1001111" when x"3",
    "1100110" when x"4",
    "1101101" when x"5",
    "1111101" when x"6",
    "0000111" when x"7",
    "1111111" when x"8",
    "1101111" when x"9",
    "1110111" when x"A",
    "1111100" when x"B",
    "0111001" when x"C",
    "1011110" when x"D",
    "1111001" when x"E",
    "1110001" when x"F",
    "0000000" when others;                   -- 'U', 'X' itd. w symulacji
end architecture rtl;
