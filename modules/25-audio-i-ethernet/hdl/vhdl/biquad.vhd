-- Filtr IIR drugiego rzędu (biquad, 25.02), postać bezpośrednia I:
--   y[n] = b0·x[n] + b1·x[n-1] + b2·x[n-2] - a1·y[n-1] - a2·y[n-2]
-- Współczynniki Q2.16 (18 bitów), próbki 24 bity, akumulator 48 bitów; jedna mnożarka w 5 taktach, wynik
-- zaokrąglony (+2^15, przesunięcie o 16) i nasycony do 24 bitów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity biquad is
  port (
    clk            : in  std_logic;
    rst            : in  std_logic;
    we             : in  std_logic;
    x              : in  signed(23 downto 0);
    b0, b1, b2     : in  signed(17 downto 0);
    a1, a2         : in  signed(17 downto 0);
    y              : out signed(23 downto 0) := (others => '0');
    y_wazne        : out std_logic := '0'
  );
end entity biquad;

architecture rtl of biquad is
  signal x0, x1, x2, y1, y2 : signed(23 downto 0) := (others => '0');
  signal acc : signed(47 downto 0) := (others => '0');
  signal k   : natural range 0 to 7 := 7;
begin
  process (clk)
    variable c   : signed(17 downto 0);
    variable s   : signed(23 downto 0);
    variable il  : signed(41 downto 0);
    variable w   : signed(47 downto 0);
    variable nas : signed(23 downto 0);
  begin
    if rising_edge(clk) then
      y_wazne <= '0';
      case k is
        when 0      => c := b0; s := x0;
        when 1      => c := b1; s := x1;
        when 2      => c := b2; s := x2;
        when 3      => c := a1; s := y1;
        when others => c := a2; s := y2;
      end case;
      il := c * s;
      w  := shift_right(acc + 32768, 16);
      if w > 8388607 then nas := to_signed(8388607, 24);
      elsif w < -8388608 then nas := to_signed(-8388608, 24);
      else nas := resize(w, 24);
      end if;
      if rst = '1' then
        x0 <= (others => '0'); x1 <= (others => '0'); x2 <= (others => '0');
        y1 <= (others => '0'); y2 <= (others => '0'); acc <= (others => '0'); k <= 7; y <= (others => '0');
      elsif k = 7 then
        if we = '1' then x0 <= x; acc <= (others => '0'); k <= 0; end if;
      elsif k = 5 then
        y <= nas; y_wazne <= '1';
        x2 <= x1; x1 <= x0; y2 <= y1; y1 <= nas;
        k <= 7;
      else
        if k >= 3 then acc <= acc - resize(il, 48); else acc <= acc + resize(il, 48); end if;
        k <= k + 1;
      end if;
    end if;
  end process;
end architecture rtl;
