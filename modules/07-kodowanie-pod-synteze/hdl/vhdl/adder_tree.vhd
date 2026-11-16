-- Suma N liczb bez znaku w drzewie sumatorów, opcjonalnie z rejestrem po każdym poziomie.
-- Szerokość wyniku i opóźnienie wynikają z generików: W + clog2(N) bitów, opóźnienie clog2(N) taktów
-- przy PIPELINED = true, 0 przy false. N musi być potęgą dwójki (co najmniej 2).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.rtl_pkg.all;

entity adder_tree is
  generic (
    N         : positive := 8;
    W         : positive := 8;
    PIPELINED : boolean  := true
  );
  port (
    clk : in  std_logic;
    x   : in  std_logic_vector(N * W - 1 downto 0);
    sum : out std_logic_vector(W + clog2(N) - 1 downto 0)
  );
end entity adder_tree;

architecture rtl of adder_tree is
  constant L  : natural  := clog2(N);
  constant OW : positive := W + L;
  type node_t is array (0 to 2 * N - 2) of unsigned(OW - 1 downto 0);
  signal node : node_t;                              -- węzły jak w kopcu: liście N-1 .. 2N-2, korzeń 0
begin
  assert N >= 2 and is_pow2(N)
    report "adder_tree: N = " & integer'image(N) & " nie jest potega dwojki" severity failure;

  g_leaf : for i in 0 to N - 1 generate
    node(N - 1 + i) <= resize(unsigned(x((i + 1) * W - 1 downto i * W)), OW);
  end generate g_leaf;

  g_node : for i in 0 to N - 2 generate
    g_reg : if PIPELINED generate
      process (clk)
      begin
        if rising_edge(clk) then
          node(i) <= node(2 * i + 1) + node(2 * i + 2);
        end if;
      end process;
    end generate g_reg;
    g_comb : if not PIPELINED generate
      node(i) <= node(2 * i + 1) + node(2 * i + 2);
    end generate g_comb;
  end generate g_node;

  sum <= std_logic_vector(node(0));
end architecture rtl;
