-- Testbench dekodera rozkazów: wszystkie 256 kodów, model z porównań zakresów liczb.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_instr_decode is
end entity tb_instr_decode;

architecture sim of tb_instr_decode is
  signal instr     : std_logic_vector(7 downto 0);
  signal cls       : std_logic_vector(2 downto 0);
  signal is_branch : std_logic;
begin
  dut : entity work.instr_decode
    port map (instr => instr, cls => cls, is_branch => is_branch);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable e      : natural;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for i in 0 to 255 loop
      instr <= std_logic_vector(to_unsigned(i, 8));
      wait for 1 ns;
      if i >= 128 then    e := 1;
      elsif i >= 64 then  e := 2;
      elsif i >= 32 then  e := 3;
      elsif i >= 16 then  e := 4;
      elsif i = 0 then    e := 0;
      else                e := 7;
      end if;
      check(to_integer(unsigned(cls)) = e, "cls dla " & integer'image(i));
      check((is_branch = '1') = (e = 3), "is_branch dla " & integer'image(i));
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
