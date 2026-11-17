-- Testbench rozgalezienie: N = 64, NDUP = 1 i 8. Wyjście = wejście przesunięte o N pozycji
-- (przesunięcia tylko w taktach z zezwoleniem opóźnionym przez en_r); obie wersje identyczne.
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_rozgalezienie is
end entity tb_rozgalezienie;

architecture sim of tb_rozgalezienie is
  constant N : positive := 64;
  signal clk, en, d : std_logic := '0';
  signal q1, q8     : std_logic;
  signal model      : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal en_d       : std_logic := '0';
  signal przes      : natural := 0;
  signal fin        : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u1 : entity work.rozgalezienie generic map (N => N, NDUP => 1) port map (clk => clk, en => en, d => d, q => q1);
  u8 : entity work.rozgalezienie generic map (N => N, NDUP => 8) port map (clk => clk, en => en, d => d, q => q8);

  process (clk)
  begin
    if rising_edge(clk) then
      en_d <= en;
      if en_d = '1' then
        model <= model(N - 2 downto 0) & d;
        przes <= przes + 1;
      end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 9;
    variable r      : real;
    variable l      : line;
    variable errors : integer := 0;
  begin
    for t in 1 to 2000 loop
      wait until falling_edge(clk);
      if q1 /= model(N - 1) or q8 /= model(N - 1) then
        write(l, "takt " & integer'image(t) & ": wyjscie niezgodne z modelem"); writeline(output, l);
        errors := errors + 1;
      end if;
      uniform(s1, s2, r);
      if r < 0.67 then en <= '1'; else en <= '0'; end if;
      uniform(s1, s2, r);
      if r < 0.5 then d <= '1'; else d <= '0'; end if;
    end loop;
    write(l, "przesuniec: " & integer'image(przes)); writeline(output, l);
    if errors = 0 and przes > 3 * N then
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
