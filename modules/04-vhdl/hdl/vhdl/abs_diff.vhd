-- Moduł różnicy |a - b| dla liczb bez znaku — przykład jawnych konwersji typów numeric_std.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity abs_diff is
  generic (W : positive := 8);
  port (
    a, b   : in  std_logic_vector(W - 1 downto 0);  -- liczby bez znaku
    y      : out std_logic_vector(W - 1 downto 0);  -- |a - b| zawsze mieści się w W bitach
    a_lt_b : out std_logic
  );
end entity abs_diff;

architecture rtl of abs_diff is
  signal diff : signed(W downto 0);         -- różnica może być ujemna: W + 1 bitów ze znakiem
begin
  -- slv -> unsigned (interpretacja) -> resize do W+1 (dopisuje zero) -> signed (bit znaku = 0, wartość bez zmian)
  diff <= signed(resize(unsigned(a), W + 1)) - signed(resize(unsigned(b), W + 1));

  -- abs na signed, potem z powrotem: signed -> unsigned -> obcięcie do W bitów -> slv
  y      <= std_logic_vector(resize(unsigned(abs(diff)), W));
  a_lt_b <= diff(W);                         -- bit znaku różnicy
end architecture rtl;
