-- Prosta jednostka arytmetyczno-logiczna: instrukcja case wybiera operację.
--   op: 000 a+b, 001 a-b, 010 a and b, 011 a or b, 100 a xor b, 101 a<<1, 110 a>>1, 111 b
--   carry: przeniesienie (add), brak pożyczki (sub, czyli a >= b), bit wysunięty (przesunięcia), 0 (pozostałe)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
  generic (W : positive := 8);
  port (
    a, b  : in  std_logic_vector(W - 1 downto 0);
    op    : in  std_logic_vector(2 downto 0);
    y     : out std_logic_vector(W - 1 downto 0);
    carry : out std_logic;
    zero  : out std_logic
  );
end entity alu;

architecture rtl of alu is
  signal res : std_logic_vector(W - 1 downto 0);
begin
  process (all)
    variable ext : unsigned(W downto 0);     -- wynik z dodatkowym bitem przeniesienia
  begin
    carry <= '0';                            -- wartości domyślne: brak zatrzasków
    ext   := (others => '0');
    case op is
      when "000" =>
        ext   := resize(unsigned(a), W + 1) + resize(unsigned(b), W + 1);
        res   <= std_logic_vector(ext(W - 1 downto 0));
        carry <= ext(W);
      when "001" =>
        -- a - b = a + not b + 1; przeniesienie = 1 oznacza brak pożyczki
        ext   := resize(unsigned(a), W + 1) + resize(unsigned(not b), W + 1) + 1;
        res   <= std_logic_vector(ext(W - 1 downto 0));
        carry <= ext(W);
      when "010" => res <= a and b;
      when "011" => res <= a or b;
      when "100" => res <= a xor b;
      when "101" =>
        res   <= a(W - 2 downto 0) & '0';
        carry <= a(W - 1);
      when "110" =>
        res   <= '0' & a(W - 1 downto 1);
        carry <= a(0);
      when others => res <= b;
    end case;
  end process;

  y    <= res;
  zero <= '1' when unsigned(res) = 0 else '0';
end architecture rtl;
