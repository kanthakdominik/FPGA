-- Testbench sumatora z nasyceniem: wszystkie pary liczb 4-bitowych ze znakiem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_sat_add is
end entity tb_sat_add;

architecture sim of tb_sat_add is
  constant W  : positive := 4;
  signal a, b : std_logic_vector(W - 1 downto 0);
  signal y    : std_logic_vector(W - 1 downto 0);
  signal sat  : std_logic;
begin
  dut : entity work.sat_add
    generic map (W => W)
    port map (a => a, b => b, y => y, sat => sat);

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
        e := s;
        if s > 7 then
          e := 7;
        elsif s < -8 then
          e := -8;
        end if;
        check(to_integer(signed(y)) = e and (sat = '1') = (s /= e),
              integer'image(i) & " + " & integer'image(j) & " = " & integer'image(to_integer(signed(y))));
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
