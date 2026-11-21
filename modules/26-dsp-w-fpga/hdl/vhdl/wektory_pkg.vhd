-- Odczyt wektorów testowych z plików .hex (jedna liczba szesnastkowa w wierszu, 4 albo 8 cyfr) — dla testbenchy
-- modułu 26. Wartości 16-bitowe trafiają do młodszych bitów słowa 32-bitowego.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

package wektory_pkg is
  type wektor_t is array (natural range <>) of std_logic_vector(31 downto 0);
  impure function czytaj_hex(nazwa : string; n : positive; bity : positive) return wektor_t;
  procedure pisz(s : string);
end package wektory_pkg;

package body wektory_pkg is
  impure function czytaj_hex(nazwa : string; n : positive; bity : positive) return wektor_t is
    file f       : text;
    variable st  : file_open_status;
    variable l   : line;
    variable v16 : std_logic_vector(15 downto 0);
    variable v32 : std_logic_vector(31 downto 0);
    variable r   : wektor_t(0 to n - 1) := (others => (others => '0'));
  begin
    file_open(st, f, nazwa, read_mode);
    assert st = open_ok report "FAIL: brak pliku " & nazwa severity failure;
    for i in 0 to n - 1 loop
      exit when endfile(f);
      readline(f, l);
      if bity = 16 then
        hread(l, v16);
        r(i) := x"0000" & v16;
      else
        hread(l, v32);
        r(i) := v32;
      end if;
    end loop;
    file_close(f);
    return r;
  end function;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
end package body wektory_pkg;
