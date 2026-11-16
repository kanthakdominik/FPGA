-- Testbench liczenia jedynek: wszystkie 256 wartości, model liczy bity dzieleniem przez 2.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_popcount is
end entity tb_popcount;

architecture sim of tb_popcount is
  constant W   : positive := 8;
  signal d     : std_logic_vector(W - 1 downto 0);
  signal count : natural range 0 to W;
begin
  dut : entity work.popcount
    generic map (W => W)
    port map (d => d, count => count);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable v, n   : natural;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for i in 0 to 2 ** W - 1 loop
      d <= std_logic_vector(to_unsigned(i, W));
      wait for 1 ns;
      v := i;
      n := 0;
      while v > 0 loop
        n := n + v mod 2;
        v := v / 2;
      end loop;
      check(count = n, "popcount(" & integer'image(i) & ") = " & integer'image(count));
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
