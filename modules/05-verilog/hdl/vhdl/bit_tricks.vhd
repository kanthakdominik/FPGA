-- Operacje bitowe: potęga dwójki, najmłodsza jedynka, odwrócenie bitów, redukcje.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bit_tricks is
  generic (W : positive := 8);
  port (
    x        : in  std_logic_vector(W - 1 downto 0);
    is_pow2  : out std_logic;
    lowest   : out std_logic_vector(W - 1 downto 0);
    rev      : out std_logic_vector(W - 1 downto 0);
    parity   : out std_logic;
    all_ones : out std_logic
  );
end entity bit_tricks;

architecture rtl of bit_tricks is
  signal u : unsigned(W - 1 downto 0);
begin
  u        <= unsigned(x);
  is_pow2  <= '1' when u /= 0 and (u and (u - 1)) = 0 else '0';
  lowest   <= std_logic_vector(u and (not u + 1));
  parity   <= xor x;                            -- operator redukcji (VHDL-2008)
  all_ones <= and x;

  g_rev : for i in 0 to W - 1 generate
    rev(i) <= x(W - 1 - i);
  end generate g_rev;
end architecture rtl;
