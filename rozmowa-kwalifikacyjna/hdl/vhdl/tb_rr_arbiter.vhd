-- Testbench zadania 5 (VHDL): rotacja przy stałych zgłoszeniach, potem losowe zgłoszenia trwające do przydziału;
-- model, jedna jedynka w przydziale, najdłuższe oczekiwanie <= 3 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_rr_arbiter is
end entity;

architecture sim of tb_rr_arbiter is
  signal clk   : std_logic := '0';
  signal fin   : boolean := false;
  signal rst   : std_logic := '1';
  signal req   : std_logic_vector(3 downto 0) := "0000";
  signal grant : std_logic_vector(3 downto 0);

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.rr_arbiter generic map (N => 4) port map (clk => clk, rst => rst, req => req, grant => grant);

  process
    type waits_t is array (0 to 3) of natural;
    variable s1, s2                      : positive := 5;
    variable r                           : real;
    variable ptr                         : natural := 0;
    variable e_grant, granted, nowe          : std_logic_vector(3 downto 0);
    variable found                       : boolean;
    variable errors, n_grant, max_wait   : natural := 0;
    variable waits                       : waits_t := (others => 0);

    procedure sprawdz is
    begin
      e_grant := "0000"; found := false;
      for k in 0 to 3 loop
        if not found and req((ptr + k) mod 4) = '1' then
          found := true;
          e_grant((ptr + k) mod 4) := '1';
          ptr := (ptr + k + 1) mod 4;
        end if;
      end loop;
      if grant /= e_grant then say("blad w " & time'image(now)); errors := errors + 1; end if;
      if (grant and not req) /= "0000" then errors := errors + 1; end if;
      if grant /= "0000" then n_grant := n_grant + 1; end if;
      for j in 0 to 3 loop
        if req(j) = '1' and grant(j) = '0' then waits(j) := waits(j) + 1; else waits(j) := 0; end if;
        if waits(j) > max_wait then max_wait := waits(j); end if;
      end loop;
      granted := grant;
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    req <= "1111";
    for i in 0 to 7 loop
      wait until rising_edge(clk);
      if grant /= std_logic_vector(shift_left(to_unsigned(1, 4), i mod 4)) then
        say("rotacja: takt " & integer'image(i)); errors := errors + 1;
      end if;
      sprawdz;
    end loop;
    for i in 0 to 999 loop
      wait until falling_edge(clk);
      for j in 0 to 3 loop
        uniform(s1, s2, r);
        if r < 0.5 then nowe(j) := '1'; else nowe(j) := '0'; end if;
      end loop;
      req <= (req and not granted) or nowe;
      wait until rising_edge(clk);
      sprawdz;
    end loop;
    say("przydzialow " & integer'image(n_grant) & ", najdluzsze oczekiwanie " & integer'image(max_wait) & " taktow");
    if max_wait > 3 then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
