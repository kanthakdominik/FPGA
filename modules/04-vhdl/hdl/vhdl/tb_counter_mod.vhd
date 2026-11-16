-- Testbench licznika modulo: porównanie z modelem w każdym takcie, zezwolenie przerywane, reset w trakcie pracy.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_counter_mod is
end entity tb_counter_mod;

architecture sim of tb_counter_mod is
  constant MODULO : positive  := 5;
  constant T      : time      := 10 ns;
  signal clk      : std_logic := '0';
  signal done     : boolean   := false;
  signal rst      : std_logic := '1';
  signal en       : std_logic := '0';
  signal count    : natural range 0 to MODULO - 1;
  signal wrap     : std_logic;
begin
  clk <= not clk after T / 2 when not done;

  dut : entity work.counter_mod
    generic map (MODULO => MODULO)
    port map (clk => clk, rst => rst, en => en, count => count, wrap => wrap);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable model  : natural := 0;          -- oczekiwany stan licznika
    variable wraps  : natural := 0;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    wait until falling_edge(clk);            -- pierwsze zbocze wykonało reset
    rst <= '0';
    for i in 0 to 59 loop
      -- sprawdzenie stanu po ostatnim zboczu narastającym
      check(count = model, "count=" & integer'image(count) & " oczekiwano " & integer'image(model));
      check((wrap = '1') = (en = '1' and model = MODULO - 1), "zly wrap w takcie " & integer'image(i));
      if wrap = '1' then
        wraps := wraps + 1;
      end if;
      -- nowe pobudzenia i stan, który powinien powstać na następnym zboczu
      if i = 40 then
        rst <= '1'; en <= '1';
        model := 0;
      else
        rst <= '0';
        if i mod 4 = 3 then
          en <= '0';
        else
          en <= '1';
          model := (model + 1) mod MODULO;
        end if;
      end if;
      wait until falling_edge(clk);
    end loop;
    check(wraps > 5, "za malo przejsc przez MODULO - 1");

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
