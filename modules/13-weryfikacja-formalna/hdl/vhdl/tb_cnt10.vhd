-- Testbench cnt10: 200 taktów z losowym en, model w zmiennej; sprawdzane q i wrap w każdym takcie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_cnt10 is
end entity tb_cnt10;

architecture sim of tb_cnt10 is
  signal clk  : std_logic := '0';
  signal done : boolean   := false;
  signal rst  : std_logic := '1';
  signal en   : std_logic := '0';
  signal q    : unsigned(3 downto 0);
  signal wrap : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.cnt10
    port map (clk => clk, rst => rst, en => en, q => q, wrap => wrap);

  process
    variable m, errors, n_wrap : natural  := 0;
    variable seed1, seed2      : positive := 13;
    variable r                 : real;
    variable exp_wrap          : std_logic;
    variable l                 : line;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 199 loop
      uniform(seed1, seed2, r);
      en <= '1' when r < 0.75 else '0';
      wait for 1 ns;
      exp_wrap := '1' when en = '1' and m = 9 else '0';
      if q /= m or wrap /= exp_wrap then
        report "takt " & integer'image(n) & ": q=" & integer'image(to_integer(q)) & ", oczekiwano " &
               integer'image(m) severity warning;
        errors := errors + 1;
      end if;
      if wrap = '1' then
        n_wrap := n_wrap + 1;
      end if;
      if en = '1' then
        m := (m + 1) mod 10;
      end if;
      wait until falling_edge(clk);
    end loop;
    if n_wrap = 0 then
      report "pokrycie: brak wrap" severity warning;
      errors := errors + 1;
    end if;
    write(l, "przejsc 9 -> 0: " & integer'image(n_wrap));
    writeline(output, l);
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
