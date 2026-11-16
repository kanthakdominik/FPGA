-- Testbench detektorów 1011 (Moore i Mealy): ustalony ciąg z nakładającymi się wzorcami, potem losowe bity.
-- Model: rejestr ostatnich bitów. Moore: y = '1', gdy ostatnie 4 PRZYJĘTE bity to 1011 (takt później);
-- Mealy: y = '1', gdy ostatnie 3 przyjęte bity to 101, a bieżący x = '1' (w tym samym takcie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_seq_det is
end entity tb_seq_det;

architecture sim of tb_seq_det is
  signal clk              : std_logic := '0';
  signal done             : boolean   := false;
  signal rst              : std_logic := '1';
  signal x                : std_logic := '0';
  signal y_moore, y_mealy : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  u_moore : entity work.seq_det_moore port map (clk => clk, rst => rst, x => x, y => y_moore);
  u_mealy : entity work.seq_det_mealy port map (clk => clk, rst => rst, x => x, y => y_mealy);

  stim : process
    constant PAT            : std_logic_vector(15 downto 0) := "1011011101100101";
    variable hist           : std_logic_vector(3 downto 0)  := "0000";   -- najnowszy bit w hist(0)
    variable xv             : std_logic;
    variable errors         : natural  := 0;
    variable hits_moore     : natural  := 0;
    variable hits_mealy     : natural  := 0;
    variable l              : line;
    variable seed1, seed2   : positive := 17;
    variable r              : real;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 1999 loop
      if (y_moore = '1') /= (hist = "1011") then
        errors := errors + 1;
        report "bit " & integer'image(n) & ": Moore y=" & to_string(y_moore) severity warning;
      end if;
      if y_moore = '1' then
        hits_moore := hits_moore + 1;
      end if;
      if n < 16 then
        xv := PAT(15 - n);
      else
        uniform(seed1, seed2, r);
        xv := '1' when r < 0.5 else '0';
      end if;
      x <= xv;
      wait for 1 ns;
      if (y_mealy = '1') /= (hist(2 downto 0) = "101" and xv = '1') then
        errors := errors + 1;
        report "bit " & integer'image(n) & ": Mealy y=" & to_string(y_mealy) severity warning;
      end if;
      if y_mealy = '1' then
        hits_mealy := hits_mealy + 1;
      end if;
      wait until falling_edge(clk);                            -- zbocze przyjęło x
      hist := hist(2 downto 0) & xv;
    end loop;

    -- Moore zgłasza każde wykrycie takt później — liczby różnią się najwyżej o ostatnie wykrycie
    if hits_mealy < 50 or hits_moore > hits_mealy or hits_mealy - hits_moore > 1 then
      errors := errors + 1;
      report "wykrycia: Moore " & integer'image(hits_moore) & ", Mealy " & integer'image(hits_mealy) severity warning;
    end if;
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
