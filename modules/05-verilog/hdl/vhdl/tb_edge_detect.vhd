-- Testbench detektora zboczy: sekwencja pseudolosowa, porównanie z poprzednią wartością wejścia.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_edge_detect is
end entity tb_edge_detect;

architecture sim of tb_edge_detect is
  constant SEQ : std_logic_vector(0 to 31) := "01101110001011011100010100111010";
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  signal d     : std_logic := '0';
  signal rise, fall, any : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.edge_detect
    port map (clk => clk, d => d, rise => rise, fall => fall, any => any);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable prev   : std_logic := '0';
    variable n_rise : natural := 0;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    wait until falling_edge(clk);
    for k in SEQ'range loop
      d <= SEQ(k);
      wait for 1 ns;
      check(rise = (SEQ(k) and not prev) and fall = (not SEQ(k) and prev) and any = (SEQ(k) xor prev),
            "takt " & integer'image(k));
      if rise = '1' then
        n_rise := n_rise + 1;
      end if;
      prev := SEQ(k);
      wait until falling_edge(clk);
    end loop;
    check(n_rise > 0, "brak zboczy w tescie");

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
