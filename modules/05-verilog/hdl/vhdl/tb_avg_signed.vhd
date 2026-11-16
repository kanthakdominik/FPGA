-- Testbench średniej ze znakiem: wszystkie pary liczb 4-bitowych, model floor((a + b) / 2).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_avg_signed is
end entity tb_avg_signed;

architecture sim of tb_avg_signed is
  constant W     : positive := 4;
  signal a, b, y : std_logic_vector(W - 1 downto 0);
begin
  dut : entity work.avg_signed
    generic map (W => W)
    port map (a => a, b => b, y => y);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable s, e   : integer;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for i in -8 to 7 loop
      for j in -8 to 7 loop
        a <= std_logic_vector(to_signed(i, W));
        b <= std_logic_vector(to_signed(j, W));
        wait for 1 ns;
        s := i + j;
        -- "/" zaokrągla do zera, "mod" daje wynik nieujemny dla dzielnika dodatniego
        e := (s - (s mod 2)) / 2;
        check(to_integer(signed(y)) = e, "avg(" & integer'image(i) & ", " & integer'image(j) & ")");
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
