-- Funkcje pomocnicze wspólne dla modułów (VHDL nie ma wbudowanego $clog2).
library ieee;
use ieee.std_logic_1164.all;

package util_pkg is
  -- najmniejsza liczba bitów potrzebna do zapisania wartości 0 .. n-1 (co najmniej 1)
  function clog2(n : positive) return positive;
end package util_pkg;

package body util_pkg is
  function clog2(n : positive) return positive is
    variable bity : positive := 1;
  begin
    while 2 ** bity < n loop
      bity := bity + 1;
    end loop;
    return bity;
  end function;
end package body util_pkg;
