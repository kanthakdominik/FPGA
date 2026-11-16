-- Maksimum z N liczb bez znaku — drzewo binarne: log2(N) poziomów porównań. N musi być potęgą dwójki.
-- Węzły jak w kopcu: liście node(N-1 .. 2N-2), węzeł i ma dzieci 2i+1 i 2i+2, korzeń node(0).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rtl_pkg.all;

entity max_tree is
  generic (
    N : positive := 8;
    W : positive := 8
  );
  port (
    x : in  std_logic_vector(N * W - 1 downto 0);
    y : out std_logic_vector(W - 1 downto 0)
  );
end entity max_tree;

architecture rtl of max_tree is
  type node_t is array (0 to 2 * N - 2) of unsigned(W - 1 downto 0);
  signal node : node_t;
begin
  assert N >= 2 and is_pow2(N)
    report "max_tree: N = " & integer'image(N) & " nie jest potega dwojki" severity failure;

  g_leaf : for i in 0 to N - 1 generate
    node(N - 1 + i) <= unsigned(x((i + 1) * W - 1 downto i * W));
  end generate g_leaf;

  g_node : for i in 0 to N - 2 generate
    node(i) <= node(2 * i + 1) when node(2 * i + 1) > node(2 * i + 2) else node(2 * i + 2);
  end generate g_node;

  y <= std_logic_vector(node(0));
end architecture rtl;
