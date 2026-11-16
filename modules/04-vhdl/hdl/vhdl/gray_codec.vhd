-- Konwersja binarny <-> Gray i parzystość, z użyciem funkcji z pakietu gray_pkg.
library ieee;
use ieee.std_logic_1164.all;
use work.gray_pkg.all;

entity gray_codec is
  generic (W : positive := 8);
  port (
    bin_in   : in  std_logic_vector(W - 1 downto 0);
    gray_out : out std_logic_vector(W - 1 downto 0);
    gray_in  : in  std_logic_vector(W - 1 downto 0);
    bin_out  : out std_logic_vector(W - 1 downto 0);
    par      : out std_logic                 -- parzystość bin_in: '1' przy nieparzystej liczbie jedynek
  );
end entity gray_codec;

architecture rtl of gray_codec is
begin
  gray_out <= bin2gray(bin_in);
  bin_out  <= gray2bin(gray_in);
  par      <= parity(bin_in);
end architecture rtl;
