-- Testbench adder_tree: wersja kombinacyjna i potokowa (N = 8), N = 16 z W = 4 oraz N = 2.
-- Wynik porównany z sumą sprzed opóźnienia potoku; co 50 taktów same maksima (sprawdzenie szerokości).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_adder_tree is
end entity tb_adder_tree;

architecture sim of tb_adder_tree is
  signal clk      : std_logic := '0';
  signal done     : boolean   := false;
  signal x8, x16  : std_logic_vector(63 downto 0) := (others => '0');   -- N = 8, W = 8 i N = 16, W = 4
  signal x2       : std_logic_vector(15 downto 0) := (others => '0');   -- N = 2, W = 8
  signal s8c, s8p : std_logic_vector(10 downto 0);
  signal s16      : std_logic_vector(7 downto 0);
  signal s2       : std_logic_vector(8 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  u_8c  : entity work.adder_tree generic map (N => 8,  W => 8, PIPELINED => false) port map (clk => clk, x => x8,  sum => s8c);
  u_8p  : entity work.adder_tree generic map (N => 8,  W => 8, PIPELINED => true)  port map (clk => clk, x => x8,  sum => s8p);
  u_16p : entity work.adder_tree generic map (N => 16, W => 4, PIPELINED => true)  port map (clk => clk, x => x16, sum => s16);
  u_2p  : entity work.adder_tree generic map (N => 2,  W => 8, PIPELINED => true)  port map (clk => clk, x => x2,  sum => s2);

  stim : process
    type hist_t is array (0 to 299) of natural;
    variable h8, h16, h2  : hist_t;
    variable v8, v16      : std_logic_vector(63 downto 0);
    variable v2           : std_logic_vector(15 downto 0);
    variable errors       : natural  := 0;
    variable l            : line;
    variable seed1, seed2 : positive := 13;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure check;
  begin
    for c in 0 to 299 loop
      wait until falling_edge(clk);
      -- wyjścia potokowe: suma wejść sprzed log2(N) taktów
      if c >= 3 then
        check(to_integer(unsigned(s8p)) = h8(c - 3), "N=8 potok, takt " & integer'image(c));
      end if;
      if c >= 4 then
        check(to_integer(unsigned(s16)) = h16(c - 4), "N=16, takt " & integer'image(c));
      end if;
      if c >= 1 then
        check(to_integer(unsigned(s2)) = h2(c - 1), "N=2, takt " & integer'image(c));
      end if;
      if c mod 50 = 7 then
        v8  := (others => '1');
        v16 := (others => '1');
        v2  := (others => '1');
      else
        for i in 0 to 7 loop
          v8(i * 8 + 7 downto i * 8)  := std_logic_vector(to_unsigned(rnd(256), 8));
          v16(i * 8 + 7 downto i * 8) := std_logic_vector(to_unsigned(rnd(256), 8));
        end loop;
        v2 := std_logic_vector(to_unsigned(rnd(65536), 16));
      end if;
      x8  <= v8;
      x16 <= v16;
      x2  <= v2;
      h8(c) := 0;  h16(c) := 0;  h2(c) := 0;
      for i in 0 to 7 loop
        h8(c) := h8(c) + to_integer(unsigned(v8(i * 8 + 7 downto i * 8)));
      end loop;
      for i in 0 to 15 loop
        h16(c) := h16(c) + to_integer(unsigned(v16(i * 4 + 3 downto i * 4)));
      end loop;
      for i in 0 to 1 loop
        h2(c) := h2(c) + to_integer(unsigned(v2(i * 8 + 7 downto i * 8)));
      end loop;
      wait for 1 ns;
      check(to_integer(unsigned(s8c)) = h8(c), "N=8 komb., takt " & integer'image(c));
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
