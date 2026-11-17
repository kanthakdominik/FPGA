-- Testbench pomiar_czestotliwosci: odniesienie 50 MHz, okno 2500 taktów; zegary mierzone 37,3 MHz
-- (oczekiwane ok. 1865) i 100 MHz (5000). Pięć wyników każdego miernika w granicach ±1.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_pomiar_czestotliwosci is
end entity tb_pomiar_czestotliwosci;

architecture sim of tb_pomiar_czestotliwosci is
  constant BRAMKA : positive := 2500;
  signal clk_ref, clk_a, clk_b : std_logic := '0';
  signal rst    : std_logic := '1';
  signal wa, wb : std_logic_vector(23 downto 0);
  signal va, vb : std_logic;
  signal fin    : boolean := false;
begin
  clk_ref <= not clk_ref after 10 ns when not fin else clk_ref;
  process
  begin
    wait for 3.3 ns;
    while not fin loop
      clk_a <= not clk_a;
      wait for 13.405 ns;
    end loop;
    wait;
  end process;
  process
  begin
    wait for 1.7 ns;
    while not fin loop
      clk_b <= not clk_b;
      wait for 5 ns;
    end loop;
    wait;
  end process;

  u_a : entity work.pomiar_czestotliwosci generic map (CW => 24, BRAMKA => BRAMKA)
    port map (clk_ref => clk_ref, rst => rst, clk_mier => clk_a, wynik => wa, wynik_valid => va);
  u_b : entity work.pomiar_czestotliwosci generic map (CW => 24, BRAMKA => BRAMKA)
    port map (clk_ref => clk_ref, rst => rst, clk_mier => clk_b, wynik => wb, wynik_valid => vb);

  process
    constant OA : real := 1.0e9 / 26.81 * real(BRAMKA) / 50.0e6;
    constant OB : real := 100.0e6 * real(BRAMKA) / 50.0e6;
    variable l : line;
    variable errors, na, nb : integer := 0;
    variable x : real;
  begin
    wait for 95 ns;
    rst <= '0';
    while na < 5 or nb < 5 loop
      wait until rising_edge(clk_ref);
      if va = '1' then
        na := na + 1;
        x := real(to_integer(unsigned(wa)));
        write(l, "37,3 MHz: " & integer'image(to_integer(unsigned(wa)))); writeline(output, l);
        if x < OA - 1.0 or x > OA + 1.0 then errors := errors + 1; end if;
      end if;
      if vb = '1' then
        nb := nb + 1;
        x := real(to_integer(unsigned(wb)));
        write(l, "100 MHz: " & integer'image(to_integer(unsigned(wb)))); writeline(output, l);
        if x < OB - 1.0 or x > OB + 1.0 then errors := errors + 1; end if;
      end if;
    end loop;
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
