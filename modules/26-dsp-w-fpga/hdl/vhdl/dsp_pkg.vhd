-- Wspólne funkcje modułu 26: nasycenie, zaokrąglenie (przesunięcie z dodaniem połowy) i wybór współczynnika
-- z wektora wsp (h_i w bitach 16i+15..16i — ten sam format co w wersjach Verilog i SystemVerilog).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package dsp_pkg is
  function nasyc(v : signed; bity : positive) return signed;
  function zaokr(v : signed; s : positive) return signed;
  function wsp_h(wsp : std_logic_vector; i : natural) return signed;
end package dsp_pkg;

package body dsp_pkg is
  function nasyc(v : signed; bity : positive) return signed is
    variable r : signed(bity - 1 downto 0);
  begin
    if v > to_signed(2 ** (bity - 1) - 1, v'length) then
      r := (others => '1'); r(bity - 1) := '0';
    elsif v < to_signed(-(2 ** (bity - 1)), v'length) then
      r := (others => '0'); r(bity - 1) := '1';
    else
      r := resize(v, bity);
    end if;
    return r;
  end function;

  function zaokr(v : signed; s : positive) return signed is
  begin
    return shift_right(v + to_signed(2 ** (s - 1), v'length), s);
  end function;

  function wsp_h(wsp : std_logic_vector; i : natural) return signed is
    variable w : std_logic_vector(wsp'length - 1 downto 0) := wsp;
  begin
    return signed(w(16 * i + 15 downto 16 * i));
  end function;
end package body dsp_pkg;
