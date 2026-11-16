-- Testbench |a - b|: wszystkie pary liczb 4-bitowych bez znaku.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_abs_diff is
end entity tb_abs_diff;

architecture sim of tb_abs_diff is
  constant W   : positive := 4;
  signal a, b  : std_logic_vector(W - 1 downto 0);
  signal y     : std_logic_vector(W - 1 downto 0);
  signal a_lt_b : std_logic;
begin
  dut : entity work.abs_diff
    generic map (W => W)
    port map (a => a, b => b, y => y, a_lt_b => a_lt_b);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for i in 0 to 2 ** W - 1 loop
      for j in 0 to 2 ** W - 1 loop
        a <= std_logic_vector(to_unsigned(i, W));
        b <= std_logic_vector(to_unsigned(j, W));
        wait for 1 ns;
        check(to_integer(unsigned(y)) = abs (i - j) and (a_lt_b = '1') = (i < j),
              "|" & integer'image(i) & " - " & integer'image(j) & "|");
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
