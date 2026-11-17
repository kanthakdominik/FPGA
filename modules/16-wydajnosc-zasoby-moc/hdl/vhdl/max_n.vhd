-- Maksimum z 16 liczb W-bitowych (16.03). DRZEWO = false: łańcuch 15 porównań (głębokość 15),
-- DRZEWO = true: drzewo porównań (głębokość 4). Rejestry na wejściu i wyjściu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity max_n is
  generic (
    W      : positive := 8;
    DRZEWO : boolean  := true
  );
  port (
    clk : in  std_logic;
    x   : in  std_logic_vector(16 * W - 1 downto 0);
    y   : out std_logic_vector(W - 1 downto 0)
  );
end entity max_n;

architecture rtl of max_n is
  type tab_t is array (natural range <>) of unsigned(W - 1 downto 0);
  signal x_r   : tab_t(0 to 15);
  signal t     : tab_t(0 to 14);             -- drzewo: t(0..7), t(8..11), t(12..13), t(14)
  signal m     : tab_t(0 to 15);             -- łańcuch
  signal wynik : unsigned(W - 1 downto 0);

  function wiekszy(p, q : unsigned) return unsigned is
  begin
    if p > q then
      return p;
    else
      return q;
    end if;
  end function;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 15 loop
        x_r(i) <= unsigned(x((i + 1) * W - 1 downto i * W));
      end loop;
      y <= std_logic_vector(wynik);
    end if;
  end process;

  g_drzewo : if DRZEWO generate
    g_l1 : for k in 0 to 7 generate
      t(k) <= wiekszy(x_r(2 * k), x_r(2 * k + 1));
    end generate;
    g_l2 : for k in 0 to 3 generate
      t(8 + k) <= wiekszy(t(2 * k), t(2 * k + 1));
    end generate;
    g_l3 : for k in 0 to 1 generate
      t(12 + k) <= wiekszy(t(8 + 2 * k), t(8 + 2 * k + 1));
    end generate;
    t(14) <= wiekszy(t(12), t(13));
    wynik <= t(14);
  else generate
    m(0) <= x_r(0);
    g_l : for k in 1 to 15 generate
      m(k) <= wiekszy(x_r(k), m(k - 1));
    end generate;
    wynik <= m(15);
  end generate;
end architecture rtl;
