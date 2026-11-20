-- Mnożenie ze znakiem 2H × 2H bitów z czterech mnożeń (H+1) × (H+1) (19.02): przy H = 17 — 34 × 34
-- z czterech bloków 18 × 18. a = ah·2^H + al (al bez znaku, ah ze znakiem),
-- a·b = ah·bh·2^2H + (ah·bl + al·bh)·2^H + al·bl. Potok 3 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mnoz_szeroki is
  generic (H : positive := 17);
  port (
    clk       : in  std_logic;
    in_valid  : in  std_logic;
    a         : in  std_logic_vector(2 * H - 1 downto 0);
    b         : in  std_logic_vector(2 * H - 1 downto 0);
    out_valid : out std_logic := '0';
    p         : out std_logic_vector(4 * H - 1 downto 0)
  );
end entity mnoz_szeroki;

architecture rtl of mnoz_szeroki is
  signal a_r, b_r            : std_logic_vector(2 * H - 1 downto 0);
  signal al, ah, bl, bh      : signed(H downto 0);
  signal pll, plh, phl, phh  : signed(2 * H + 1 downto 0);
  signal v1, v2              : std_logic := '0';
begin
  al <= signed('0' & a_r(H - 1 downto 0));
  ah <= resize(signed(a_r(2 * H - 1 downto H)), H + 1);
  bl <= signed('0' & b_r(H - 1 downto 0));
  bh <= resize(signed(b_r(2 * H - 1 downto H)), H + 1);

  process (clk)
  begin
    if rising_edge(clk) then
      a_r <= a;
      b_r <= b;
      v1  <= in_valid;
      pll <= al * bl;
      plh <= al * bh;
      phl <= ah * bl;
      phh <= ah * bh;
      v2  <= v1;
      p   <= std_logic_vector(shift_left(resize(phh, 4 * H), 2 * H) + shift_left(resize(plh, 4 * H), H)
                              + shift_left(resize(phl, 4 * H), H) + resize(pll, 4 * H));
      out_valid <= v2;
    end if;
  end process;
end architecture rtl;
