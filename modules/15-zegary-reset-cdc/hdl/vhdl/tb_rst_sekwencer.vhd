-- Testbench rst_sekwencer: clk_a 100 MHz, clk_b 58,8 MHz, 30 impulsów arst_n w losowych chwilach.
-- Sprawdzane: ustawienie resetu w obu domenach natychmiast (bez czekania na zegar), zdjęcie rst_a
-- dokładnie na STAGES-tym zboczu clk_a po zwolnieniu arst_n, zdjęcie rst_b tylko na zboczu clk_b
-- i nie wcześniej niż rst_a, liczba taktów clk_b od rst_a do rst_b w granicach STAGES...STAGES+1.
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_rst_sekwencer is
end entity tb_rst_sekwencer;

architecture sim of tb_rst_sekwencer is
  constant STAGES : positive := 2;
  signal clk_a, clk_b : std_logic := '0';
  signal fin          : boolean   := false;
  signal arst_n       : std_logic := '0';
  signal rst_a, rst_b : std_logic;
  signal n_a, n_b     : natural := 0;
  signal zeruj        : boolean := false;
  signal err_a, err_b, err_s : natural := 0;
begin
  clk_a <= not clk_a after 5 ns when not fin;
  clk_b <= not clk_b after 8.5 ns when not fin;

  dut : entity work.rst_sekwencer
    generic map (STAGES => STAGES)
    port map (arst_n => arst_n, clk_a => clk_a, rst_a => rst_a, clk_b => clk_b, rst_b => rst_b);

  -- liczniki zboczy po zwolnieniu arst_n
  process (clk_a, zeruj)
  begin
    if zeruj then
      n_a <= 0;
    elsif rising_edge(clk_a) and arst_n = '1' then
      n_a <= n_a + 1;
    end if;
  end process;
  process (clk_b, zeruj)
  begin
    if zeruj then
      n_b <= 0;
    elsif rising_edge(clk_b) and arst_n = '1' and rst_a = '0' then
      n_b <= n_b + 1;
    end if;
  end process;

  process (rst_a)
  begin
    if falling_edge(rst_a) then
      -- n_a zwiększone w tym samym kroku czasu, ale o cykl delta później: STAGES - 1 albo STAGES
      if n_a /= STAGES - 1 and n_a /= STAGES then err_a <= err_a + 1; end if;
      if clk_a /= '1' then err_a <= err_a + 1; end if;
    end if;
  end process;
  process (rst_b)
  begin
    if falling_edge(rst_b) then
      if rst_a = '1' then err_b <= err_b + 1; end if;
      if clk_b /= '1' then err_b <= err_b + 1; end if;
      if n_b < STAGES - 1 or n_b > STAGES + 1 then err_b <= err_b + 1; end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 9;
    variable x      : real;
    variable l      : line;
    variable errors : natural;
  begin
    for k in 1 to 30 loop
      uniform(s1, s2, x);
      wait for (20.0 + x * 280.0) * 1 ns;
      arst_n <= '0';
      wait for 0.5 ns;
      if rst_a /= '1' or rst_b /= '1' then err_s <= err_s + 1; end if;
      uniform(s1, s2, x);
      wait for (5.0 + floor(x * 450.0) * 0.1 + 0.05) * 1 ns;   -- nigdy w chwili zbocza
      zeruj <= true;
      wait for 0 ns;
      zeruj <= false;
      arst_n <= '1';
      wait for 200 ns;
      if rst_a = '1' or rst_b = '1' then err_s <= err_s + 1; end if;
    end loop;
    write(l, string'("impulsow resetu: 30"));
    writeline(output, l);
    errors := err_a + err_b + err_s;
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
