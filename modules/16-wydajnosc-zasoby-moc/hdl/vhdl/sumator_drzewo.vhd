-- Suma ośmiu liczb W-bitowych drzewem sumatorów (16.01). Rejestry wejściowe i wyjściowy zawsze;
-- PIPE (0..2) dodaje rejestry potoku po 1. i 2. poziomie drzewa, RET (0..3) - dodatkowe rejestry
-- na wyjściu (materiał dla retimingu). Opóźnienie: L = 2 + PIPE + RET taktów, jeden wynik na takt.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sumator_drzewo is
  generic (
    W    : positive := 16;
    PIPE : natural  := 0;
    RET  : natural  := 0
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    x         : in  std_logic_vector(8 * W - 1 downto 0);
    out_valid : out std_logic;
    y         : out std_logic_vector(W + 2 downto 0)
  );
end entity sumator_drzewo;

architecture rtl of sumator_drzewo is
  constant L : positive := 2 + PIPE + RET;
  type t0_t is array (0 to 7) of unsigned(W - 1 downto 0);
  type t1_t is array (0 to 3) of unsigned(W downto 0);
  type t2_t is array (0 to 1) of unsigned(W + 1 downto 0);
  type tr_t is array (0 to RET) of unsigned(W + 2 downto 0);
  signal x_r        : t0_t;
  signal s1, s1_p   : t1_t;
  signal s2, s2_p   : t2_t;
  signal ret_r      : tr_t;                  -- ret_r(0) = rejestr wyjściowy
  signal v_r        : std_logic_vector(L - 1 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      for i in 0 to 7 loop
        x_r(i) <= unsigned(x((i + 1) * W - 1 downto i * W));
      end loop;
    end if;
  end process;

  g_s1 : for k in 0 to 3 generate
    s1(k) <= resize(x_r(2 * k), W + 1) + resize(x_r(2 * k + 1), W + 1);
  end generate;
  g_p1 : if PIPE >= 1 generate
    s1_p <= s1 when rising_edge(clk);
  else generate
    s1_p <= s1;
  end generate;

  g_s2 : for k in 0 to 1 generate
    s2(k) <= resize(s1_p(2 * k), W + 2) + resize(s1_p(2 * k + 1), W + 2);
  end generate;
  g_p2 : if PIPE >= 2 generate
    s2_p <= s2 when rising_edge(clk);
  else generate
    s2_p <= s2;
  end generate;

  process (clk)
  begin
    if rising_edge(clk) then
      ret_r(0) <= resize(s2_p(0), W + 3) + resize(s2_p(1), W + 3);
      for i in 1 to RET loop
        ret_r(i) <= ret_r(i - 1);
      end loop;
      if rst = '1' then
        v_r <= (others => '0');
      else
        v_r <= v_r(L - 2 downto 0) & in_valid;
      end if;
    end if;
  end process;

  y         <= std_logic_vector(ret_r(RET));
  out_valid <= v_r(L - 1);
end architecture rtl;
