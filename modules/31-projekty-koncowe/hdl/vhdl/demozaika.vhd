-- Demozaikowanie RGGB metodą dwuliniową (31.05): okno 3×3 z dwóch linii opóźniających, brakujące składowe
-- jako zaokrąglone średnie sąsiadów, parzystość środka okna z liczników. Jak w wersjach Verilog i SV.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity demozaika is
  generic (L : positive := 800);
  port (
    clk        : in  std_logic;
    de, hs, vs : in  std_logic;
    raw        : in  std_logic_vector(7 downto 0);
    o_de       : out std_logic := '0';
    o_hs, o_vs : out std_logic := '1';
    rgb        : out std_logic_vector(23 downto 0) := (others => '0')
  );
end entity demozaika;

architecture rtl of demozaika is
  type lin1_t is array (0 to L - 1) of std_logic_vector(10 downto 0);
  type lin2_t is array (0 to L - 1) of std_logic_vector(7 downto 0);
  signal lin1 : lin1_t := (others => (others => '0'));
  signal lin2 : lin2_t := (others => (others => '0'));
  signal w0, w1 : std_logic_vector(10 downto 0) := (others => '0');
  signal w2 : std_logic_vector(7 downto 0) := (others => '0');
  signal a, an : natural range 0 to L - 1 := 0;
  signal p00, p01, p02, p10, p11, p12, p20, p21, p22 : unsigned(7 downto 0) := (others => '0');
  signal s1, s2 : std_logic_vector(2 downto 0) := "011";
  signal de_p, kol, wier : std_logic := '0';
  signal vs_p : std_logic := '1';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if de = '1' then w0 <= de & hs & vs & raw; else w0 <= de & hs & vs & x"00"; end if;
      a <= an;
      if an = L - 1 then an <= 0; else an <= an + 1; end if;
      lin1(a) <= w0;
      lin2(a) <= w1(7 downto 0);
      w1 <= lin1(an);
      w2 <= lin2(an);
      p00 <= unsigned(w0(7 downto 0)); p01 <= p00; p02 <= p01;
      p10 <= unsigned(w1(7 downto 0)); p11 <= p10; p12 <= p11;
      p20 <= unsigned(w2);             p21 <= p20; p22 <= p21;
      s1 <= w1(10 downto 8);
      s2 <= s1;
      de_p <= s2(2);
      vs_p <= s2(0);
      if s2(2) = '1' then kol <= not kol; else kol <= '0'; end if;
      if vs_p = '1' and s2(0) = '0' then wier <= '0';
      elsif de_p = '1' and s2(2) = '0' then wier <= not wier;
      end if;
    end if;
  end process;

  process (clk)
    variable krzyz, przek : unsigned(9 downto 0);
    variable poz, pion : unsigned(8 downto 0);
  begin
    if rising_edge(clk) then
      krzyz := resize(p01, 10) + p10 + p12 + p21 + 2;
      przek := resize(p00, 10) + p02 + p20 + p22 + 2;
      poz   := resize(p10, 9) + p12 + 1;
      pion  := resize(p01, 9) + p21 + 1;
      o_de <= s2(2); o_hs <= s2(1); o_vs <= s2(0);
      if wier = '0' and kol = '0' then
        rgb <= std_logic_vector(p11 & krzyz(9 downto 2) & przek(9 downto 2));
      elsif wier = '0' then
        rgb <= std_logic_vector(poz(8 downto 1) & p11 & pion(8 downto 1));
      elsif kol = '0' then
        rgb <= std_logic_vector(pion(8 downto 1) & p11 & poz(8 downto 1));
      else
        rgb <= std_logic_vector(przek(9 downto 2) & krzyz(9 downto 2) & p11);
      end if;
    end if;
  end process;
end architecture rtl;
