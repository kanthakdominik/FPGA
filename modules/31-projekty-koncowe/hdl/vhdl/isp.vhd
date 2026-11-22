-- Potok obróbki obrazu (31.05): demozaika -> luminancja -> filtr3x3 -> wybór trybu (0 kolor, 1 szarość,
-- 2 rozmycie, 3 Sobel, 4 krawędzie), tryb zmieniany na początku vs, suma jasności ramki. Jak w wersjach
-- Verilog i SystemVerilog.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity isp is
  generic (L : positive := 800; PROG : natural := 96);
  port (
    clk        : in  std_logic;
    tryb       : in  unsigned(2 downto 0);
    de, hs, vs : in  std_logic;
    raw        : in  std_logic_vector(7 downto 0);
    o_de       : out std_logic := '0';
    o_hs, o_vs : out std_logic := '1';
    rgb        : out std_logic_vector(23 downto 0) := (others => '0');
    suma_y     : out unsigned(31 downto 0) := (others => '0')
  );
end entity isp;

architecture rtl of isp is
  signal d_de, d_hs, d_vs, f_de, f_hs, f_vs : std_logic;
  signal d_rgb : std_logic_vector(23 downto 0);
  signal y8 : std_logic_vector(7 downto 0) := (others => '0');
  signal y_de : std_logic := '0';
  signal y_hs, y_vs, f_vs_p, y_vs_p : std_logic := '1';
  signal tryb_r : unsigned(2 downto 0) := "000";
  signal f_tryb : std_logic_vector(1 downto 0);
  signal f_piks : std_logic_vector(7 downto 0);
  signal akum : unsigned(31 downto 0) := (others => '0');
begin
  u_dem : entity work.demozaika generic map (L => L)
    port map (clk => clk, de => de, hs => hs, vs => vs, raw => raw, o_de => d_de, o_hs => d_hs, o_vs => d_vs,
              rgb => d_rgb);

  process (clk)
    variable s : unsigned(16 downto 0);
  begin
    if rising_edge(clk) then
      s := 77 * resize(unsigned(d_rgb(23 downto 16)), 17) + 150 * resize(unsigned(d_rgb(15 downto 8)), 17)
           + 29 * resize(unsigned(d_rgb(7 downto 0)), 17) + 128;
      y8 <= std_logic_vector(s(15 downto 8));
      y_de <= d_de; y_hs <= d_hs; y_vs <= d_vs;
    end if;
  end process;

  f_tryb <= "01" when tryb_r = 2 else "10" when tryb_r = 3 else "11" when tryb_r = 4 else "00";
  u_filtr : entity work.filtr3x3 generic map (L => L, PROG => PROG)
    port map (clk => clk, tryb => f_tryb, de => y_de, hs => y_hs, vs => y_vs, piks => y8, o_de => f_de,
              o_hs => f_hs, o_vs => f_vs, o_piks => f_piks);

  process (clk)
  begin
    if rising_edge(clk) then
      f_vs_p <= f_vs;
      if f_vs_p = '1' and f_vs = '0' then
        if tryb > 4 then tryb_r <= "000"; else tryb_r <= tryb; end if;
      end if;
      if tryb_r = 0 then
        o_de <= d_de; o_hs <= d_hs; o_vs <= d_vs;
        if d_de = '1' then rgb <= d_rgb; else rgb <= (others => '0'); end if;
      else
        o_de <= f_de; o_hs <= f_hs; o_vs <= f_vs;
        if f_de = '1' then rgb <= f_piks & f_piks & f_piks; else rgb <= (others => '0'); end if;
      end if;
      y_vs_p <= y_vs;
      if y_vs_p = '1' and y_vs = '0' then
        suma_y <= akum;
        akum <= (others => '0');
      elsif y_de = '1' then
        akum <= akum + unsigned(y8);
      end if;
    end if;
  end process;
end architecture rtl;
