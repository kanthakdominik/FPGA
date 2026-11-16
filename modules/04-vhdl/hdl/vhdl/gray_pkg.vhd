-- Pakiet z funkcjami do kodu Graya i parzystości.
-- Funkcje działają na wektorach dowolnej długości (parametr bez ograniczeń: std_logic_vector).
library ieee;
use ieee.std_logic_1164.all;

package gray_pkg is
  function bin2gray(b : std_logic_vector) return std_logic_vector;
  function gray2bin(g : std_logic_vector) return std_logic_vector;
  function parity(v : std_logic_vector) return std_logic;
end package gray_pkg;

package body gray_pkg is
  function bin2gray(b : std_logic_vector) return std_logic_vector is
    -- normalizacja zakresu: argument może mieć dowolne indeksy, np. (12 downto 5)
    alias bn     : std_logic_vector(b'length - 1 downto 0) is b;
    variable g   : std_logic_vector(b'length - 1 downto 0);
  begin
    g(g'high) := bn(bn'high);
    for i in g'high - 1 downto 0 loop
      g(i) := bn(i + 1) xor bn(i);
    end loop;
    return g;
  end function;

  function gray2bin(g : std_logic_vector) return std_logic_vector is
    alias gn     : std_logic_vector(g'length - 1 downto 0) is g;
    variable b   : std_logic_vector(g'length - 1 downto 0);
  begin
    b(b'high) := gn(gn'high);
    for i in b'high - 1 downto 0 loop
      b(i) := b(i + 1) xor gn(i);           -- łańcuch XOR od najstarszego bitu
    end loop;
    return b;
  end function;

  function parity(v : std_logic_vector) return std_logic is
    variable p : std_logic := '0';
  begin
    for i in v'range loop
      p := p xor v(i);
    end loop;
    return p;
  end function;
end package body gray_pkg;
