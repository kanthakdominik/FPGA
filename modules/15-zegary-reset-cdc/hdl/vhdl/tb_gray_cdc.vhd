-- Testbench gray_cdc i synchronizacji wielobitowej. Część 1: układ gray_cdc (100 MHz -> 36,6 MHz) - kolejne
-- odczyty w domenie docelowej różnią się o 0...4 (licznik źródłowy rośnie najwyżej o 1 na takt).
-- Część 2: przyczyna - ten sam licznik 4-bitowy wysłany do synchronizatorów z rozrzutem opóźnień bitów
-- (0...2,1 ns, jak na różnych ścieżkach w układzie): w kodzie binarnym pojawiają się skoki, których licznik
-- nigdy nie wykonał, w kodzie Graya - nigdy.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_gray_cdc is
end entity tb_gray_cdc;

architecture sim of tb_gray_cdc is
  constant W : positive := 4;
  signal clk_f, clk_s : std_logic := '0';
  signal fin          : boolean   := false;
  signal rst          : std_logic := '1';
  signal inc          : std_logic := '0';
  signal src_count, dst_count : unsigned(W - 1 downto 0);
  signal bin_r, gray_r : unsigned(W - 1 downto 0) := (others => '0');
  signal bin_sk, gray_sk, bin_s, gray_s : std_logic_vector(W - 1 downto 0);
  signal errs, n_prob, zle_bin, zle_gray : natural := 0;

  function g2b(g : std_logic_vector) return unsigned is
    variable b : unsigned(g'range);
  begin
    b(g'high) := g(g'high);
    for i in g'high - 1 downto g'low loop
      b(i) := b(i + 1) xor g(i);
    end loop;
    return b;
  end function;
begin
  clk_f <= not clk_f after 5 ns when not fin;
  clk_s <= not clk_s after 13.65 ns when not fin;

  dut : entity work.gray_cdc
    generic map (W => W)
    port map (clk_src => clk_f, rst_src => rst, inc => inc, src_count => src_count,
              clk_dst => clk_s, dst_count => dst_count);

  process (clk_f)
    variable s1, s2 : positive := 11;
    variable x      : real;
  begin
    if falling_edge(clk_f) then
      uniform(s1, s2, x);
      if x < 0.5 then inc <= '1'; else inc <= '0'; end if;
    end if;
    if rising_edge(clk_f) and rst = '0' then
      bin_r  <= bin_r + 1;
      gray_r <= (bin_r + 1) xor shift_right(bin_r + 1, 1);
    end if;
  end process;

  -- rozrzut opóźnień bitów przed synchronizatorem
  g_skew : for i in 0 to W - 1 generate
    bin_sk(i)  <= bin_r(i) after i * 700 ps;
    gray_sk(i) <= gray_r(i) after i * 700 ps;
  end generate;
  u_bin : entity work.sync_bit
    generic map (STAGES => 2, W => W)
    port map (clk => clk_s, d => bin_sk, q => bin_s);
  u_gray : entity work.sync_bit
    generic map (STAGES => 2, W => W)
    port map (clk => clk_s, d => gray_sk, q => gray_s);

  process (clk_s)
    variable dst_prev, b_prev, g_prev : unsigned(W - 1 downto 0) := (others => '0');
  begin
    if falling_edge(clk_s) and rst = '0' then
      n_prob <= n_prob + 1;
      if dst_count - dst_prev > 4 then
        report "skok licznika" severity warning;
        errs <= errs + 1;
      end if;
      dst_prev := dst_count;
      if unsigned(bin_s) - b_prev > 4 then zle_bin <= zle_bin + 1; end if;
      if g2b(gray_s) - g_prev > 4 then zle_gray <= zle_gray + 1; end if;
      b_prev := unsigned(bin_s);
      g_prev := g2b(gray_s);
    end if;
  end process;

  process
    variable l      : line;
    variable errors : natural;
  begin
    wait for 100 ns;
    rst <= '0';
    wait for 60000 ns;
    write(l, "gray_cdc: " & integer'image(n_prob) & " probek; rozrzut bitow: wartosci bledne binarnie " &
             integer'image(zle_bin) & ", w kodzie Graya " & integer'image(zle_gray));
    writeline(output, l);
    errors := errs;
    if zle_gray /= 0 then errors := errors + 1; end if;
    if zle_bin = 0 then errors := errors + 1; end if;
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
