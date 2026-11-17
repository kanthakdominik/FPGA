-- Testbench bicie_serca: POLOKRES = 7, zegar 10 ns - zmiana stanu co 70 ns; reset zeruje wyjście.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_bicie_serca is
end entity tb_bicie_serca;

architecture sim of tb_bicie_serca is
  signal clk, rst, led : std_logic := '0';
  signal fin : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.bicie_serca generic map (POLOKRES => 7) port map (clk => clk, rst => rst, led => led);

  process
    variable l : line;
    variable errors, zmian : integer := 0;
    variable t_ost : time := 0 ns;
  begin
    rst <= '1';
    wait for 23 ns;
    rst <= '0';
    while now < 2023 ns loop
      wait on led for 2023 ns - now;
      if led'event then
        if zmian > 0 and now - t_ost /= 70 ns then
          write(l, "polokres " & time'image(now - t_ost)); writeline(output, l);
          errors := errors + 1;
        end if;
        t_ost := now;
        zmian := zmian + 1;
      end if;
    end loop;
    rst <= '1';
    wait for 50 ns;
    if led /= '0' then
      write(l, string'("reset nie zeruje wyjscia")); writeline(output, l);
      errors := errors + 1;
    end if;
    if errors = 0 and zmian >= 25 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow, " & integer'image(zmian) & " zmian");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
