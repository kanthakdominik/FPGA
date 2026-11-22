-- Testbench zadania 1 (VHDL): losowe d na zboczu opadającym, porównanie rise i fall z modelem w każdym takcie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_edge_detect is
end entity;

architecture sim of tb_edge_detect is
  signal clk        : std_logic := '0';
  signal fin        : boolean := false;
  signal rst        : std_logic := '1';
  signal d          : std_logic := '0';
  signal rise, fall : std_logic;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.edge_detect port map (clk => clk, rst => rst, d => d, rise => rise, fall => fall);

  process
    variable s1, s2                 : positive := 11;
    variable r                      : real;
    variable prev                   : std_logic := '0';
    variable errors, n_rise, n_fall : natural := 0;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 499 loop
      wait until falling_edge(clk);
      uniform(s1, s2, r);
      if r < 0.34 then d <= not d; end if;
      wait until rising_edge(clk);
      if rise /= (d and not prev) or fall /= (not d and prev) then
        say("blad w " & time'image(now));
        errors := errors + 1;
      end if;
      if rise = '1' then n_rise := n_rise + 1; end if;
      if fall = '1' then n_fall := n_fall + 1; end if;
      prev := d;
    end loop;
    say("zboczy narastajacych " & integer'image(n_rise) & ", opadajacych " & integer'image(n_fall));
    if n_rise < 50 or n_fall < 50 then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
