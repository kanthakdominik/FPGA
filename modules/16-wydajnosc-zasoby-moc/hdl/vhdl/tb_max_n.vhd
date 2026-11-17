-- Testbench max_n: łańcuch i drzewo na tych samych danych; wynik = maksimum z 16 wejść po 2 taktach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_max_n is
end entity tb_max_n;

architecture sim of tb_max_n is
  constant W : positive := 8;
  signal clk      : std_logic := '0';
  signal x        : std_logic_vector(16 * W - 1 downto 0) := (others => '0');
  signal y_l, y_d : std_logic_vector(W - 1 downto 0);
  signal o1, o2   : unsigned(W - 1 downto 0) := (others => '0');
  signal fin      : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_l : entity work.max_n generic map (W => W, DRZEWO => false) port map (clk => clk, x => x, y => y_l);
  u_d : entity work.max_n generic map (W => W, DRZEWO => true)  port map (clk => clk, x => x, y => y_d);

  process (clk)
    variable m : unsigned(W - 1 downto 0);
  begin
    if rising_edge(clk) then
      m := (others => '0');
      for i in 0 to 15 loop
        if unsigned(x((i + 1) * W - 1 downto i * W)) > m then
          m := unsigned(x((i + 1) * W - 1 downto i * W));
        end if;
      end loop;
      o1 <= m;
      o2 <= o1;
    end if;
  end process;

  process
    variable s1, s2 : positive := 5;
    variable r      : real;
    variable l      : line;
    variable errors : integer := 0;
  begin
    for n in 1 to 1000 loop
      wait until falling_edge(clk);
      if n > 3 and (unsigned(y_l) /= o2 or unsigned(y_d) /= o2) then
        write(l, "takt " & integer'image(n) & ": lancuch " & integer'image(to_integer(unsigned(y_l)))
              & ", drzewo " & integer'image(to_integer(unsigned(y_d))) & ", oczekiwano " & integer'image(to_integer(o2)));
        writeline(output, l);
        errors := errors + 1;
      end if;
      for i in 0 to 15 loop
        uniform(s1, s2, r);
        if n mod 5 = 0 then
          x((i + 1) * W - 1 downto i * W) <= std_logic_vector(to_unsigned(7, W));
        else
          x((i + 1) * W - 1 downto i * W) <= std_logic_vector(to_unsigned(integer(floor(r * 256.0)) mod 256, W));
        end if;
      end loop;
      if n mod 7 = 0 then x(W - 1 downto 0) <= (others => '1'); end if;
      if n mod 11 = 0 then x(16 * W - 1 downto 15 * W) <= (others => '1'); end if;
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
