-- Testbench: obie wersje addsel dają ten sam wynik co model a + (sel ? c : b).
-- Wszystkie kombinacje dla W = 4 (2 * 16 * 16 * 16 = 8192 przypadki).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_addsel is
end entity tb_addsel;

architecture sim of tb_addsel is
  constant W       : positive := 4;
  signal sel       : std_logic;
  signal a, b, c   : std_logic_vector(W - 1 downto 0);
  signal y2, y1    : std_logic_vector(W downto 0);
begin
  u_two : entity work.addsel_two_adders
    generic map (W => W)
    port map (sel => sel, a => a, b => b, c => c, y => y2);
  u_one : entity work.addsel_one_adder
    generic map (W => W)
    port map (sel => sel, a => a, b => b, c => c, y => y1);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable expect : natural;
  begin
    for s in 0 to 1 loop
      for i in 0 to 2 ** W - 1 loop
        for j in 0 to 2 ** W - 1 loop
          for k in 0 to 2 ** W - 1 loop
            if s = 1 then
              sel <= '1';
              expect := i + k;
            else
              sel <= '0';
              expect := i + j;
            end if;
            a <= std_logic_vector(to_unsigned(i, W));
            b <= std_logic_vector(to_unsigned(j, W));
            c <= std_logic_vector(to_unsigned(k, W));
            wait for 1 ns;
            if to_integer(unsigned(y2)) /= expect or to_integer(unsigned(y1)) /= expect then
              errors := errors + 1;
              report "addsel: sel=" & integer'image(s) & " a=" & integer'image(i)
                     & " b=" & integer'image(j) & " c=" & integer'image(k) severity warning;
            end if;
          end loop;
        end loop;
      end loop;
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
