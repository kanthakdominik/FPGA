-- Dekoder SECDED (18.06): syndrom = XOR numerów pozycji z jedynką, parzystość = XOR wszystkich bitów.
-- Parzystość '1' - błąd pojedynczy na pozycji syndromu (poprawiany); syndrom /= 0 przy parzystości '0' -
-- błąd podwójny (wykryty).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity secded_dekoder is
  generic (
    K : positive := 32;
    R : positive := 6
  );
  port (
    kod        : in  std_logic_vector(K + R downto 0);
    dane       : out std_logic_vector(K - 1 downto 0);
    pojedynczy : out std_logic;
    podwojny   : out std_logic;
    syndrom    : out std_logic_vector(R - 1 downto 0)
  );
end entity secded_dekoder;

architecture rtl of secded_dekoder is
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
begin
  process (kod)
    variable s      : unsigned(R - 1 downto 0);
    variable popr   : std_logic_vector(K + R downto 0);
    variable d      : natural;
  begin
    s := (others => '0');
    for p in 1 to K + R loop
      if kod(p) = '1' then
        s := s xor to_unsigned(p, R);
      end if;
    end loop;
    popr       := kod;
    pojedynczy <= '0';
    podwojny   <= '0';
    if (xor kod) = '1' then
      if to_integer(s) <= K + R then
        popr(to_integer(s)) := not popr(to_integer(s));
        pojedynczy <= '1';
      else
        podwojny <= '1';
      end if;
    elsif s /= 0 then
      podwojny <= '1';
    end if;
    d := 0;
    for p in 1 to K + R loop
      if not potega2(p) then
        dane(d) <= popr(p);
        d := d + 1;
      end if;
    end loop;
    syndrom <= std_logic_vector(s);
  end process;
end architecture rtl;
