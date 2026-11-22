-- Testbench zadania 2 (VHDL): liczniki N = 10 i N = 6 z losowym zezwoleniem, porównanie z modelem w każdym takcie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_mod_counter is
end entity;

architecture sim of tb_mod_counter is
  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal rst      : std_logic := '1';
  signal en       : std_logic := '0';
  signal q10      : unsigned(3 downto 0);
  signal q6       : unsigned(2 downto 0);
  signal c10, c6  : std_logic;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut10 : entity work.mod_counter generic map (N => 10, W => 4)
    port map (clk => clk, rst => rst, en => en, q => q10, carry => c10);
  dut6 : entity work.mod_counter generic map (N => 6, W => 3)
    port map (clk => clk, rst => rst, en => en, q => q6, carry => c6);

  process
    variable s1, s2                         : positive := 3;
    variable r                              : real;
    variable m10, m6                        : natural := 0;
    variable errors, n_en, n_c10, n_c6      : natural := 0;
    variable e10, e6                        : std_logic;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 599 loop
      wait until falling_edge(clk);
      uniform(s1, s2, r);
      if r < 0.75 then en <= '1'; else en <= '0'; end if;
      wait until rising_edge(clk);
      if en = '1' and m10 = 9 then e10 := '1'; else e10 := '0'; end if;
      if en = '1' and m6 = 5 then e6 := '1'; else e6 := '0'; end if;
      if to_integer(q10) /= m10 or to_integer(q6) /= m6 or c10 /= e10 or c6 /= e6 then
        say("blad w " & time'image(now) & ": q10=" & integer'image(to_integer(q10)) & " model " & integer'image(m10));
        errors := errors + 1;
      end if;
      if c10 = '1' then n_c10 := n_c10 + 1; end if;
      if c6 = '1' then n_c6 := n_c6 + 1; end if;
      if en = '1' then
        n_en := n_en + 1;
        m10  := (m10 + 1) mod 10;
        m6   := (m6 + 1) mod 6;
      end if;
    end loop;
    say("taktow z en " & integer'image(n_en) & ", przeniesien N=10: " & integer'image(n_c10) & ", N=6: " &
        integer'image(n_c6));
    if n_c10 /= n_en / 10 or n_c6 /= n_en / 6 then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
