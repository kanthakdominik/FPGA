-- Pakiet typów i funkcji przetwarzania obrazu: rekord piksela, typ wyliczeniowy trybu, konwersje.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package img_pkg is
  type rgb_t is record
    r, g, b : unsigned(7 downto 0);
  end record;

  type gray_mode_t is (GRAY_AVG, GRAY_LUMA, GRAY_RED);

  function to_rgb(v : std_logic_vector(23 downto 0)) return rgb_t;   -- {r, g, b} -> rekord
  function to_slv(p : rgb_t) return std_logic_vector;                -- rekord -> 24 bity
  function luma(p : rgb_t) return unsigned;                          -- (77r + 150g + 29b) / 256
end package img_pkg;

package body img_pkg is
  function to_rgb(v : std_logic_vector(23 downto 0)) return rgb_t is
  begin
    return (r => unsigned(v(23 downto 16)), g => unsigned(v(15 downto 8)), b => unsigned(v(7 downto 0)));
  end function;

  function to_slv(p : rgb_t) return std_logic_vector is
  begin
    return std_logic_vector(p.r) & std_logic_vector(p.g) & std_logic_vector(p.b);
  end function;

  function luma(p : rgb_t) return unsigned is
    variable s : unsigned(15 downto 0);
  begin
    s := resize(p.r * to_unsigned(77, 8), 16) + resize(p.g * to_unsigned(150, 8), 16)
         + resize(p.b * to_unsigned(29, 8), 16);
    return s(15 downto 8);
  end function;
end package body img_pkg;
