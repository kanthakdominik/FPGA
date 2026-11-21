-- Biquad w postaci bezpośredniej II transponowanej (26.02), jedna próbka na takt:
--   w = Q(b0·x + s1);  s1 <- b1·x - a1·w + s2;  s2 <- b2·x - a2·w;  y = w
-- Współczynniki Q2.14, stany 40 bitów. Q: ZAOKR = 0 — obcięcie (floor), 1 — zaokrąglenie do najbliższej,
-- 2 — obcięcie w stronę zera; potem nasycenie do 16 bitów. Wynik takt po we.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.dsp_pkg.all;

entity biquad_df2t is
  generic (ZAOKR : natural range 0 to 2 := 1);
  port (
    clk, rst, we       : in  std_logic;
    x                  : in  signed(15 downto 0);
    b0, b1, b2, a1, a2 : in  signed(15 downto 0);
    y                  : out signed(15 downto 0) := (others => '0');
    y_wazne            : out std_logic := '0'
  );
end entity biquad_df2t;

architecture rtl of biquad_df2t is
  signal s1, s2 : signed(39 downto 0) := (others => '0');
begin
  process (clk)
    variable v, q : signed(39 downto 0);
    variable w    : signed(15 downto 0);
  begin
    if rising_edge(clk) then
      y_wazne <= '0';
      if rst = '1' then
        s1 <= (others => '0'); s2 <= (others => '0'); y <= (others => '0');
      elsif we = '1' then
        v := resize(b0 * x, 40) + s1;
        if ZAOKR = 0 then
          q := shift_right(v, 14);
        elsif ZAOKR = 1 then
          q := shift_right(v + 8192, 14);
        elsif v < 0 then
          q := shift_right(v + 16383, 14);
        else
          q := shift_right(v, 14);
        end if;
        w       := nasyc(q, 16);
        s1      <= resize(b1 * x, 40) - resize(a1 * w, 40) + s2;
        s2      <= resize(b2 * x, 40) - resize(a2 * w, 40);
        y       <= w;
        y_wazne <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
