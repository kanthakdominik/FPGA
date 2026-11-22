-- Pomocnicze typy i funkcje testbenchy rdzeni (27.07): odczyt plików z rvasm.py (program, ślad zapisów ISS,
-- liczby kontrolne) i wypisywanie tekstu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

package rv_tb_pkg is
  type slowa_t is array (natural range <>) of std_logic_vector(31 downto 0);
  type zapisy_t is array (natural range <>) of std_logic_vector(67 downto 0);   -- adres & dane & maska
  impure function czytaj_slowa(nazwa : string; n : positive) return slowa_t;
  impure function czytaj_zapisy(nazwa : string; n : positive) return zapisy_t;
  procedure pisz(s : string);
  function hex(v : std_logic_vector) return string;
end package rv_tb_pkg;

package body rv_tb_pkg is
  impure function czytaj_slowa(nazwa : string; n : positive) return slowa_t is
    file f      : text;
    variable st : file_open_status;
    variable l  : line;
    variable v  : std_logic_vector(31 downto 0);
    variable r  : slowa_t(0 to n - 1) := (others => (others => '0'));
  begin
    file_open(st, f, nazwa, read_mode);
    assert st = open_ok report "FAIL: brak pliku " & nazwa severity failure;
    for i in 0 to n - 1 loop
      exit when endfile(f);
      readline(f, l);
      hread(l, v);
      r(i) := v;
    end loop;
    file_close(f);
    return r;
  end function;

  impure function czytaj_zapisy(nazwa : string; n : positive) return zapisy_t is
    file f      : text;
    variable st : file_open_status;
    variable l  : line;
    variable v  : std_logic_vector(67 downto 0);
    variable r  : zapisy_t(0 to n - 1) := (others => (others => '0'));
  begin
    file_open(st, f, nazwa, read_mode);
    assert st = open_ok report "FAIL: brak pliku " & nazwa severity failure;
    for i in 0 to n - 1 loop
      exit when endfile(f);
      readline(f, l);
      hread(l, v);
      r(i) := v;
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

  function hex(v : std_logic_vector) return string is
    variable l : line;
  begin
    hwrite(l, v);
    return l.all;
  end function;
end package body rv_tb_pkg;
