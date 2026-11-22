-- Plik wygenerowany przez model/dsp_model.py — nie edytować ręcznie.
-- Współczynniki obrotu FFT 64 (26.05): W_k = cos(2πk/64) - j·sin(2πk/64), k = 0..31, Q1.15 (32767).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tw_tab is
  port (
    k  : in  unsigned(4 downto 0);
    wr : out signed(15 downto 0);
    wi : out signed(15 downto 0)
  );
end entity tw_tab;

architecture rtl of tw_tab is
  type tab_t is array (0 to 31) of signed(15 downto 0);
  constant TR : tab_t := (x"7FFF", x"7F61", x"7D89", x"7A7C", x"7641", x"70E2", x"6A6D", x"62F1",
    x"5A82", x"5133", x"471C", x"3C56", x"30FB", x"2528", x"18F9", x"0C8C",
    x"0000", x"F374", x"E707", x"DAD8", x"CF05", x"C3AA", x"B8E4", x"AECD",
    x"A57E", x"9D0F", x"9593", x"8F1E", x"89BF", x"8584", x"8277", x"809F");
  constant TI : tab_t := (x"0000", x"F374", x"E707", x"DAD8", x"CF05", x"C3AA", x"B8E4", x"AECD",
    x"A57E", x"9D0F", x"9593", x"8F1E", x"89BF", x"8584", x"8277", x"809F",
    x"8001", x"809F", x"8277", x"8584", x"89BF", x"8F1E", x"9593", x"9D0F",
    x"A57E", x"AECD", x"B8E4", x"C3AA", x"CF05", x"DAD8", x"E707", x"F374");
begin
  wr <= TR(to_integer(k));
  wi <= TI(to_integer(k));
end architecture rtl;
