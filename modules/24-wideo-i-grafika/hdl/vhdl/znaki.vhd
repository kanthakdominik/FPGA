-- Nakładka tekstowa (24.03): pamięć znaków KOL × WIER (ASCII), czcionka 5×7 w komórce 8×8, powiększenie 2^SK.
-- Wejście: (x, y) piksela; wyjście piks z opóźnieniem 2 taktów. Małe litery jak wielkie, nieznane znaki puste.
-- Zapis: we, wadr = wiersz·KOL + kolumna, wkod.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity znaki is
  generic (
    KOL  : positive := 40;
    WIER : positive := 30;
    SK   : natural  := 1
  );
  port (
    clk  : in  std_logic;
    we   : in  std_logic;
    wadr : in  unsigned(10 downto 0);
    wkod : in  std_logic_vector(7 downto 0);
    x, y : in  unsigned(11 downto 0);
    piks : out std_logic := '0'
  );
end entity znaki;

architecture rtl of znaki is
  type ram_t is array (0 to KOL * WIER - 1) of std_logic_vector(7 downto 0);
  signal ram : ram_t := (others => x"20");

  function glif(k : natural) return std_logic_vector is
  begin
    case k is
      when 16#21# => return "00100001000010000100001000000000100";   -- !
      when 16#2D# => return "00000000000000011111000000000000000";   -- -
      when 16#2E# => return "00000000000000000000000000110001100";   -- .
      when 16#30# => return "01110100011001110101110011000101110";   -- 0
      when 16#31# => return "00100011000010000100001000010001110";   -- 1
      when 16#32# => return "01110100010000100010001000100011111";   -- 2
      when 16#33# => return "11111000100010000010000011000101110";   -- 3
      when 16#34# => return "00010001100101010010111110001000010";   -- 4
      when 16#35# => return "11111100001111000001000011000101110";   -- 5
      when 16#36# => return "00110010001000011110100011000101110";   -- 6
      when 16#37# => return "11111000010001000100010000100001000";   -- 7
      when 16#38# => return "01110100011000101110100011000101110";   -- 8
      when 16#39# => return "01110100011000101111000010001001100";   -- 9
      when 16#3A# => return "00000011000110000000011000110000000";   -- :
      when 16#3F# => return "01110100010000100010001000000000100";   -- ?
      when 16#41# => return "01110100011000111111100011000110001";   -- A
      when 16#42# => return "11110100011000111110100011000111110";   -- B
      when 16#43# => return "01110100011000010000100001000101110";   -- C
      when 16#44# => return "11100100101000110001100011001011100";   -- D
      when 16#45# => return "11111100001000011110100001000011111";   -- E
      when 16#46# => return "11111100001000011110100001000010000";   -- F
      when 16#47# => return "01110100011000010111100011000101111";   -- G
      when 16#48# => return "10001100011000111111100011000110001";   -- H
      when 16#49# => return "01110001000010000100001000010001110";   -- I
      when 16#4A# => return "00111000100001000010000101001001100";   -- J
      when 16#4B# => return "10001100101010011000101001001010001";   -- K
      when 16#4C# => return "10000100001000010000100001000011111";   -- L
      when 16#4D# => return "10001110111010110101100011000110001";   -- M
      when 16#4E# => return "10001100011100110101100111000110001";   -- N
      when 16#4F# => return "01110100011000110001100011000101110";   -- O
      when 16#50# => return "11110100011000111110100001000010000";   -- P
      when 16#51# => return "01110100011000110001101011001001101";   -- Q
      when 16#52# => return "11110100011000111110101001001010001";   -- R
      when 16#53# => return "01111100001000001110000010000111110";   -- S
      when 16#54# => return "11111001000010000100001000010000100";   -- T
      when 16#55# => return "10001100011000110001100011000101110";   -- U
      when 16#56# => return "10001100011000110001100010101000100";   -- V
      when 16#57# => return "10001100011000110101101011010101010";   -- W
      when 16#58# => return "10001100010101000100010101000110001";   -- X
      when 16#59# => return "10001100010101000100001000010000100";   -- Y
      when 16#5A# => return "11111000010001000100010001000011111";   -- Z
      when others => return "00000000000000000000000000000000000";
    end case;
  end function;

  signal kod    : std_logic_vector(7 downto 0) := x"20";
  signal fx, fy : natural range 0 to 7 := 0;
  signal w1     : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' and to_integer(wadr) < KOL * WIER then
        ram(to_integer(wadr)) <= wkod;
      end if;
    end if;
  end process;

  -- stopień 1: komórka i położenie w komórce
  process (clk)
    variable cx, cy, a : natural;
    variable sx, sy    : unsigned(11 downto 0);
  begin
    if rising_edge(clk) then
      cx := to_integer(shift_right(x, 3 + SK));
      cy := to_integer(shift_right(y, 3 + SK));
      if cx < KOL and cy < WIER then
        a  := cy * KOL + cx;
        w1 <= '1';
      else
        a  := 0;
        w1 <= '0';
      end if;
      kod <= ram(a);
      sx  := shift_right(x, SK);
      sy  := shift_right(y, SK);
      fx  <= to_integer(sx(2 downto 0));
      fy  <= to_integer(sy(2 downto 0));
    end if;
  end process;

  -- stopień 2: bit czcionki
  process (clk)
    variable k : natural range 0 to 255;
    variable g : std_logic_vector(34 downto 0);
  begin
    if rising_edge(clk) then
      k := to_integer(unsigned(kod));
      if k >= 16#61# and k <= 16#7A# then k := k - 16#20#; end if;
      g := glif(k);
      if w1 = '1' and fx < 5 and fy < 7 then
        piks <= g(34 - (fy * 5 + fx));
      else
        piks <= '0';
      end if;
    end if;
  end process;
end architecture rtl;
