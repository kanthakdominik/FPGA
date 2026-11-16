-- Testbench arbitra karuzelowego: losowe zgłoszenia porównane z modelem, potem rotacja przy pełnym obciążeniu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_rr_arbiter is
end entity tb_rr_arbiter;

architecture sim of tb_rr_arbiter is
  signal clk  : std_logic := '0';
  signal done : boolean   := false;
  signal rst  : std_logic := '1';
  signal req  : std_logic_vector(3 downto 0) := "0000";
  signal grant       : std_logic_vector(3 downto 0);
  signal grant_idx   : std_logic_vector(1 downto 0);
  signal grant_valid : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.rr_arbiter
    port map (clk => clk, rst => rst, req => req, grant => grant, grant_idx => grant_idx, grant_valid => grant_valid);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable last   : natural := 3;
    variable e      : std_logic_vector(3 downto 0);
    variable lfsr   : unsigned(7 downto 0) := x"C3";
    variable idx    : natural;
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
    for k in 0 to 199 loop
      if lfsr(0) = '1' then
        lfsr := shift_right(lfsr, 1) xor x"B8";
      else
        lfsr := shift_right(lfsr, 1);
      end if;
      if k >= 150 then
        req <= "1111";
      else
        req <= std_logic_vector(lfsr(3 downto 0));
      end if;
      wait for 1 ns;
      e := "0000";
      for s in 1 to 4 loop
        idx := (last + s) mod 4;
        if e = "0000" and req(idx) = '1' then
          e(idx) := '1';
        end if;
      end loop;
      check(grant = e and (grant_valid = '1') = (e /= "0000"), "takt " & integer'image(k));
      if e /= "0000" then
        check(e(to_integer(unsigned(grant_idx))) = '1', "grant_idx w takcie " & integer'image(k));
        if k >= 150 then
          check(to_integer(unsigned(grant_idx)) = (last + 1) mod 4, "brak rotacji w takcie " & integer'image(k));
        end if;
        last := to_integer(unsigned(grant_idx));
      end if;
      wait until falling_edge(clk);
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
