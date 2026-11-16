-- Testbench eliminacji drgań: drgania nie zmieniają wyjścia, zmiana następuje po
-- co najmniej STABLE_CYCLES taktach stabilnego wejścia, dokładnie dwie zmiany w teście.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_debouncer is
end entity tb_debouncer;

architecture sim of tb_debouncer is
  constant STABLE : positive  := 8;
  signal clk      : std_logic := '0';
  signal done     : boolean   := false;
  signal rst      : std_logic := '1';
  signal noisy    : std_logic := '0';
  signal clean, changed : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.debouncer
    generic map (STABLE_CYCLES => STABLE)
    port map (clk => clk, rst => rst, noisy => noisy, clean => clean, changed => changed);

  stim : process
    variable errors     : natural := 0;
    variable l          : line;
    variable run        : natural := 0;
    variable n_changes  : natural := 0;
    variable prev_clean : std_logic := '0';
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
    -- jeden takt: sprawdź wyjście i ustaw nowe wejście na opadającym zboczu
    procedure step(v : std_logic) is
    begin
      wait until falling_edge(clk);
      if changed = '1' then
        n_changes := n_changes + 1;
        check(run >= STABLE, "zmiana po " & integer'image(run) & " taktach stabilnego wejscia");
        check(clean /= prev_clean, "impuls changed bez zmiany clean");
      else
        check(clean = prev_clean, "zmiana clean bez impulsu changed");
      end if;
      prev_clean := clean;
      if v = noisy then
        run := run + 1;
      else
        run := 1;
      end if;
      noisy <= v;
    end procedure;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for k in 0 to 11 loop                        -- drgania przy wciśnięciu
      if k mod 3 /= 0 then step('1'); else step('0'); end if;
    end loop;
    for k in 0 to 19 loop
      step('1');
    end loop;
    check(clean = '1', "brak stanu 1 po stabilnym wejsciu");
    for k in 0 to 11 loop                        -- drgania przy puszczeniu
      if k mod 4 = 1 then step('1'); else step('0'); end if;
    end loop;
    for k in 0 to 19 loop
      step('0');
    end loop;
    check(clean = '0', "brak stanu 0 po stabilnym wejsciu");
    check(n_changes = 2, "liczba zmian = " & integer'image(n_changes));

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
