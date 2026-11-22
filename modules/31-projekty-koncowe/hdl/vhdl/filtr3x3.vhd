-- Filtr 3×3 na strumieniu wideo (24.06): dwie linie opóźniające po L próbek (L = H_TOT) w RAM dają trzy wiersze,
-- po dwa rejestry w każdym — okno 3×3. Piksele wygaszania = 0, więc brzegi obrazu są uzupełniane zerami.
-- de/hs/vs płyną przez te same linie opóźniające — wyjście wyrównane do środka okna. Opóźnienie: L + 4 takty.
-- tryb: 0 — bez zmian, 1 — rozmycie [1 2 1; 2 4 2; 1 2 1]/16, 2 — Sobel |Gx| + |Gy| (nasycenie 255),
-- 3 — krawędzie: Sobel ≥ PROG -> 255, inaczej 0.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity filtr3x3 is
  generic (
    L    : positive := 800;
    PROG : natural  := 128
  );
  port (
    clk        : in  std_logic;
    tryb       : in  std_logic_vector(1 downto 0);
    de, hs, vs : in  std_logic;
    piks       : in  std_logic_vector(7 downto 0);
    o_de       : out std_logic := '0';
    o_hs       : out std_logic := '0';
    o_vs       : out std_logic := '0';
    o_piks     : out std_logic_vector(7 downto 0) := (others => '0')
  );
end entity filtr3x3;

architecture rtl of filtr3x3 is
  type lin1_t is array (0 to L - 1) of std_logic_vector(10 downto 0);
  type lin2_t is array (0 to L - 1) of std_logic_vector(7 downto 0);
  signal lin1 : lin1_t := (others => (others => '0'));
  signal lin2 : lin2_t := (others => (others => '0'));
  signal a, an : natural range 0 to L - 1 := 0;
  signal w0, w1 : std_logic_vector(10 downto 0) := (others => '0');     -- {de, hs, vs, piksel}
  signal w2     : std_logic_vector(7 downto 0) := (others => '0');
  subtype p_t is natural range 0 to 255;
  signal p00, p01, p02, p10, p11, p12, p20, p21, p22 : p_t := 0;
  signal s1, s2 : std_logic_vector(2 downto 0) := "000";
begin
  process (clk)
    variable roz, gx, gy, sob : integer;
  begin
    if rising_edge(clk) then
      -- wiersz 0: wejście, piksel wygaszania = 0
      if de = '1' then w0 <= de & hs & vs & piks; else w0 <= de & hs & vs & x"00"; end if;
      -- linie opóźniające: zapis pod a, odczyt spod a + 1 -> opóźnienie dokładnie L
      a <= an;
      if an = L - 1 then an <= 0; else an <= an + 1; end if;
      lin1(a) <= w0;
      lin2(a) <= w1(7 downto 0);
      w1 <= lin1(an);
      w2 <= lin2(an);
      -- okno: kolumna 0 — prawa (najnowsza), wiersz 0 — dolny
      p00 <= to_integer(unsigned(w0(7 downto 0))); p01 <= p00; p02 <= p01;
      p10 <= to_integer(unsigned(w1(7 downto 0))); p11 <= p10; p12 <= p11;
      p20 <= to_integer(unsigned(w2));             p21 <= p20; p22 <= p21;
      s1  <= w1(10 downto 8);
      s2  <= s1;
      -- wynik
      roz := (p00 + p02 + p20 + p22 + 2 * (p01 + p10 + p12 + p21) + 4 * p11 + 8) / 16;
      gx  := (p00 + 2 * p10 + p20) - (p02 + 2 * p12 + p22);
      gy  := (p00 + 2 * p01 + p02) - (p20 + 2 * p21 + p22);
      sob := abs gx + abs gy;
      o_de <= s2(2); o_hs <= s2(1); o_vs <= s2(0);
      case tryb is
        when "00"   => o_piks <= std_logic_vector(to_unsigned(p11, 8));
        when "01"   => o_piks <= std_logic_vector(to_unsigned(roz, 8));
        when "10"   =>
          if sob > 255 then o_piks <= x"FF"; else o_piks <= std_logic_vector(to_unsigned(sob, 8)); end if;
        when others =>
          if sob >= PROG then o_piks <= x"FF"; else o_piks <= x"00"; end if;
      end case;
    end if;
  end process;
end architecture rtl;
