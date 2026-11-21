-- Sprite 16×16 (24.03): obrazek 2 bity na piksel w ROM (0 — przezroczysty), położenie (sx, sy) lewego górnego
-- rogu. Wyjścia widoczny i kolor dla piksela (x, y) z opóźnieniem 1 taktu. Różnice liczone modulo 2^12.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sprite16 is
  port (
    clk      : in  std_logic;
    x, y     : in  unsigned(11 downto 0);
    sx, sy   : in  unsigned(11 downto 0);
    widoczny : out std_logic := '0';
    kolor    : out std_logic_vector(1 downto 0) := "00"
  );
end entity sprite16;

architecture rtl of sprite16 is
  function wiersz(r : natural) return std_logic_vector is
  begin
    case r is
      when  0 => return x"00155400";   -- .....aaaaaa.....
      when  1 => return x"016AA940";   -- ...aabbbbbbaa...
      when  2 => return x"06AAAA90";   -- ..abbbbbbbbbba..
      when  3 => return x"1AAAAAA4";   -- .abbbbbbbbbbbba.
      when  4 => return x"1AFEBFA4";   -- .abbcccbbcccbba.
      when  5 => return x"6ADEB7A9";   -- abbbcacbbcacbbba
      when  6 => return x"6AFEBFA9";   -- abbbcccbbcccbbba
      when  7 => return x"6AAAAAA9";   -- abbbbbbbbbbbbbba
      when  8 => return x"6AAAAAA9";   -- abbbbbbbbbbbbbba
      when  9 => return x"6BAAAAE9";   -- abbcbbbbbbbbcbba
      when 10 => return x"6AEAABA9";   -- abbbcbbbbbbcbbba
      when 11 => return x"1ABFFEA4";   -- .abbbccccccbbba.
      when 12 => return x"1AAAAAA4";   -- .abbbbbbbbbbbba.
      when 13 => return x"06AAAA90";   -- ..abbbbbbbbbba..
      when 14 => return x"016AA940";   -- ...aabbbbbbaa...
      when others => return x"00155400";   -- .....aaaaaa.....
    end case;
  end function;
begin
  process (clk)
    variable dx, dy : unsigned(11 downto 0);
    variable r      : std_logic_vector(31 downto 0);
    variable k      : std_logic_vector(1 downto 0);
    variable b      : natural range 0 to 15;
  begin
    if rising_edge(clk) then
      dx := x - sx;
      dy := y - sy;
      r  := wiersz(to_integer(dy(3 downto 0)));
      b  := 15 - to_integer(dx(3 downto 0));                  -- piksel 0 w bitach 31..30
      k  := r(2 * b + 1 downto 2 * b);
      kolor <= k;
      if dx < 16 and dy < 16 and k /= "00" then widoczny <= '1'; else widoczny <= '0'; end if;
    end if;
  end process;
end architecture rtl;
