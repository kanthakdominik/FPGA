-- Funkcje kodu SECDED (39,32) (29.04): pozycje 0..38 słowa kodowego, bity kontrolne na pozycjach 2^k,
-- parzystość całości na pozycji 0 — jak w wersjach Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package secded_pkg is
  subtype slowo_kod is std_logic_vector(38 downto 0);
  function koduj(d : std_logic_vector(31 downto 0)) return slowo_kod;
  function syndrom(w : slowo_kod) return std_logic_vector;
  function dane(w : slowo_kod) return std_logic_vector;
end package secded_pkg;

package body secded_pkg is
  function potega2(i : natural) return boolean is
  begin
    return i = 1 or i = 2 or i = 4 or i = 8 or i = 16 or i = 32;
  end function;

  function koduj(d : std_logic_vector(31 downto 0)) return slowo_kod is
    variable w : slowo_kod := (others => '0');
    variable j : natural := 0;
    variable p : std_logic;
  begin
    for i in 1 to 38 loop
      if not potega2(i) then
        w(i) := d(j);
        j := j + 1;
      end if;
    end loop;
    for k in 0 to 5 loop
      p := '0';
      for i in 1 to 38 loop
        if (i / 2 ** k) mod 2 = 1 and i /= 2 ** k then p := p xor w(i); end if;
      end loop;
      w(2 ** k) := p;
    end loop;
    p := '0';
    for i in 1 to 38 loop p := p xor w(i); end loop;
    w(0) := p;
    return w;
  end function;

  function syndrom(w : slowo_kod) return std_logic_vector is
    variable s : std_logic_vector(5 downto 0) := (others => '0');
  begin
    for k in 0 to 5 loop
      for i in 1 to 38 loop
        if (i / 2 ** k) mod 2 = 1 then s(k) := s(k) xor w(i); end if;
      end loop;
    end loop;
    return s;
  end function;

  function dane(w : slowo_kod) return std_logic_vector is
    variable r : std_logic_vector(31 downto 0) := (others => '0');
    variable j : natural := 0;
  begin
    for i in 1 to 38 loop
      if not potega2(i) then
        r(j) := w(i);
        j := j + 1;
      end if;
    end loop;
    return r;
  end function;
end package body secded_pkg;
