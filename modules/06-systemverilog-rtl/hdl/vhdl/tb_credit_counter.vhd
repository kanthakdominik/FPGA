-- Testbench licznika kredytów: losowe, poprawne operacje take/give porównane z modelem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_credit_counter is
end entity tb_credit_counter;

architecture sim of tb_credit_counter is
  constant MAX : positive  := 4;
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  signal rst   : std_logic := '1';
  signal take, give : std_logic := '0';
  signal credits    : natural range 0 to MAX;
  signal can_take   : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.credit_counter
    generic map (MAX => MAX)
    port map (clk => clk, rst => rst, take => take, give => give, credits => credits, can_take => can_take);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable model  : natural := MAX;
    variable n_zero, n_full : natural := 0;
    variable vt, vg : boolean;
    variable lfsr   : unsigned(7 downto 0) := x"5D";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    wait until falling_edge(clk);
    rst <= '0';
    for k in 0 to 299 loop
      check(credits = model and (can_take = '1') = (model /= 0), "takt " & integer'image(k));
      if model = 0 then n_zero := n_zero + 1; end if;
      if model = MAX then n_full := n_full + 1; end if;
      if lfsr(0) = '1' then
        lfsr := shift_right(lfsr, 1) xor x"B8";
      else
        lfsr := shift_right(lfsr, 1);
      end if;
      vt := lfsr(0) = '1' and model > 0;
      vg := lfsr(1) = '1' and (model < MAX or vt);
      take <= '1' when vt else '0';
      give <= '1' when vg else '0';
      if vt and not vg then model := model - 1; end if;
      if vg and not vt then model := model + 1; end if;
      wait until falling_edge(clk);
    end loop;
    check(n_zero > 0 and n_full > 0, "test nie osiagnal stanow brzegowych");

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
