-- Koder SECDED (18.06): rozszerzony kod Hamminga - bity kontrolne na pozycjach 2^j, parzystość ogólna
-- na pozycji 0; K = 32, R = 6 -> 39 bitów. Poprawia błąd pojedynczy, wykrywa podwójny.
library ieee;
use ieee.std_logic_1164.all;

entity secded_koder is
  generic (
    K : positive := 32;
    R : positive := 6
  );
  port (
    dane : in  std_logic_vector(K - 1 downto 0);
    kod  : out std_logic_vector(K + R downto 0)
  );
end entity secded_koder;

architecture rtl of secded_koder is
  function potega2(p : natural) return boolean is
    variable v : natural := p;
  begin
    while v > 1 loop
      if v mod 2 = 1 then
        return false;
      end if;
      v := v / 2;
    end loop;
    return true;
  end function;

  function bit_ust(p, j : natural) return boolean is
  begin
    return ((p / 2 ** j) mod 2) = 1;
  end function;
begin
  process (dane)
    variable c   : std_logic_vector(K + R downto 0);
    variable d   : natural;
    variable par : std_logic;
  begin
    c := (others => '0');
    d := 0;
    for p in 1 to K + R loop
      if not potega2(p) then
        c(p) := dane(d);
        d := d + 1;
      end if;
    end loop;
    for j in 0 to R - 1 loop
      par := '0';
      for p in 1 to K + R loop
        if bit_ust(p, j) then
          par := par xor c(p);
        end if;
      end loop;
      c(2 ** j) := par;
    end loop;
    c(0) := xor c(K + R downto 1);
    kod <= c;
  end process;
end architecture rtl;
