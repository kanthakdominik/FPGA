-- Testbench sygnałów i zmiennych: q_sig to d sprzed 2 taktów, q_var — sprzed 1 taktu.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_sig_var_demo is
end entity tb_sig_var_demo;

architecture sim of tb_sig_var_demo is
  constant T   : time      := 10 ns;
  -- pseudolosowa sekwencja wejściowa
  constant SEQ : std_logic_vector(0 to 23) := "101100111000101101001110";
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  signal d     : std_logic := '0';
  signal q_sig, q_var : std_logic;
begin
  clk <= not clk after T / 2 when not done;

  dut : entity work.sig_var_demo
    port map (clk => clk, d => d, q_sig => q_sig, q_var => q_var);

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
    -- d(k) jest ustawiane na opadającym zboczu k i próbkowane na następnym narastającym
    for k in SEQ'range loop
      wait until falling_edge(clk);
      if k >= 2 then
        check(q_var = SEQ(k - 1), "q_var w takcie " & integer'image(k));
        check(q_sig = SEQ(k - 2), "q_sig w takcie " & integer'image(k));
      end if;
      d <= SEQ(k);
    end loop;

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
