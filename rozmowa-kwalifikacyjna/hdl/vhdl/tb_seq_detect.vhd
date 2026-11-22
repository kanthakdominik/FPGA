-- Testbench zadania 4 (VHDL): Moore i Mealy na tym samym losowym ciągu z wtrąconym wzorcem 1011011.
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_seq_detect is
end entity;

architecture sim of tb_seq_detect is
  signal clk                  : std_logic := '0';
  signal fin                  : boolean := false;
  signal rst                  : std_logic := '1';
  signal x                    : std_logic := '0';
  signal det_moore, det_mealy : std_logic;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut_moore : entity work.seq_moore port map (clk => clk, rst => rst, x => x, det => det_moore);
  dut_mealy : entity work.seq_mealy port map (clk => clk, rst => rst, x => x, det => det_mealy);

  process
    constant WZOR             : std_logic_vector(6 downto 0) := "1011011";
    variable s1, s2           : positive := 7;
    variable r                : real;
    variable hist             : std_logic_vector(2 downto 0) := "000";
    variable exp_mealy        : std_logic;
    variable exp_moore        : std_logic := '0';
    variable errors, n_det    : natural := 0;

    procedure takt(b : std_logic) is
    begin
      wait until falling_edge(clk);
      x <= b;
      wait until rising_edge(clk);
      if (hist & x) = "1011" then exp_mealy := '1'; else exp_mealy := '0'; end if;
      if det_mealy /= exp_mealy or det_moore /= exp_moore then
        say("blad w " & time'image(now)); errors := errors + 1;
      end if;
      if exp_mealy = '1' then n_det := n_det + 1; end if;
      exp_moore := exp_mealy;
      hist := hist(1 downto 0) & x;
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 399 loop
      if i mod 50 = 25 then
        for j in 6 downto 0 loop takt(WZOR(j)); end loop;
      end if;
      uniform(s1, s2, r);
      if r < 0.5 then takt('0'); else takt('1'); end if;
    end loop;
    takt('0');
    say("wykrytych wzorcow 1011: " & integer'image(n_det));
    if n_det < 16 then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
