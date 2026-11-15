-- Testbench samosprawdzający: dioda musi zmieniać stan dokładnie co HALF taktów.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_blink is
end entity tb_blink;

architecture sim of tb_blink is
  constant CLK_HZ   : positive := 1000;
  constant BLINK_HZ : positive := 50;
  constant HALF     : positive := CLK_HZ / (2 * BLINK_HZ);  -- 10 taktów
  constant T        : time := 10 ns;

  signal clk  : std_logic := '0';
  signal rst  : std_logic := '1';
  signal led  : std_logic;
  signal done : boolean := false;
begin
  dut : entity work.blink
    generic map (CLK_HZ => CLK_HZ, BLINK_HZ => BLINK_HZ)
    port map (clk => clk, rst => rst, led => led);

  clk <= not clk after T / 2 when not done;

  stim : process
    variable cycles : natural;
    variable prev   : std_logic;
    variable errors : natural := 0;
    variable l      : line;
  begin
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst <= '0';
    if led /= '0' then
      errors := errors + 1;
    end if;
    -- pomiar odstępu między pięcioma kolejnymi zmianami stanu
    for i in 1 to 5 loop
      prev   := led;
      cycles := 0;
      loop
        wait until rising_edge(clk);
        wait for 1 ns;
        cycles := cycles + 1;
        exit when led /= prev or cycles > 4 * HALF;
      end loop;
      -- pierwsza zmiana następuje HALF taktów po zwolnieniu resetu
      if cycles /= HALF then
        report "zmiana stanu po " & integer'image(cycles) & " taktach, oczekiwano "
          & integer'image(HALF) severity warning;
        errors := errors + 1;
      end if;
    end loop;

    -- wynik w osobnej linii, od początku wiersza (czyta go tools/run_hdl_tests.py)
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
  end process;
end architecture sim;
