-- Testbench zadania 3 (VHDL): okres clk_out 30 ns i stan wysoki 15 ns w każdym z 20 okresów (zegar 10 ns).
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_clk_div3 is
end entity;

architecture sim of tb_clk_div3 is
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal clk_out : std_logic;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.clk_div3 port map (clk => clk, rst => rst, clk_out => clk_out);

  process
    variable t_rise, t_fall, t_prev : time := 0 ns;
    variable errors                 : natural := 0;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 20 loop
      wait until rising_edge(clk_out);
      t_prev := t_rise;
      t_rise := now;
      if i > 0 and t_rise - t_prev /= 30 ns then
        say("okres " & time'image(t_rise - t_prev)); errors := errors + 1;
      end if;
      wait until falling_edge(clk_out);
      t_fall := now;
      if t_fall - t_rise /= 15 ns then
        say("stan wysoki " & time'image(t_fall - t_rise)); errors := errors + 1;
      end if;
    end loop;
    say("ostatni okres " & time'image(t_rise - t_prev) & ", stan wysoki " & time'image(t_fall - t_rise));
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;

  process
  begin
    wait for 100 us;
    say("FAIL: przekroczony czas");
    std.env.finish;
  end process;
end architecture;
