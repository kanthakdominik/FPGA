-- Testbench max_chain i max_tree: przypadki brzegowe i losowe wektory, porównanie z modelem
-- „element, od którego żaden inny nie jest większy” (inny zapis niż w układach).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_max is
end entity tb_max;

architecture sim of tb_max is
  constant N : positive := 8;
  constant W : positive := 8;
  signal x               : std_logic_vector(N * W - 1 downto 0) := (others => '0');
  signal y_chain, y_tree : std_logic_vector(W - 1 downto 0);
begin
  u_chain : entity work.max_chain generic map (N => N, W => W) port map (x => x, y => y_chain);
  u_tree  : entity work.max_tree  generic map (N => N, W => W) port map (x => x, y => y_tree);

  stim : process
    variable errors       : natural  := 0;
    variable l            : line;
    variable seed1, seed2 : positive := 7;
    variable v            : std_logic_vector(N * W - 1 downto 0);

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    procedure check is
      variable e, xi : unsigned(W - 1 downto 0) := (others => '0');
      variable greater : natural;
    begin
      for i in 0 to N - 1 loop
        xi      := unsigned(x((i + 1) * W - 1 downto i * W));
        greater := 0;
        for j in 0 to N - 1 loop
          if unsigned(x((j + 1) * W - 1 downto j * W)) > xi then
            greater := greater + 1;
          end if;
        end loop;
        if greater = 0 then
          e := xi;
        end if;
      end loop;
      if unsigned(y_chain) /= e or unsigned(y_tree) /= e then
        errors := errors + 1;
        report "x=" & to_hstring(x) & ": chain=" & to_hstring(y_chain) & " tree=" & to_hstring(y_tree)
             & ", oczekiwano " & to_hstring(e) severity warning;
      end if;
    end procedure check;
  begin
    x <= (others => '0');  wait for 1 ns;  check;              -- same zera
    x <= (others => '1');  wait for 1 ns;  check;              -- same maksima
    for k in 0 to N - 1 loop                                   -- maksimum na każdej pozycji
      v := (others => '0');
      v((k + 1) * W - 1 downto k * W) := std_logic_vector(to_unsigned(200 + k, W));
      x <= v;  wait for 1 ns;  check;
    end loop;
    for k in 0 to 999 loop
      for i in 0 to N - 1 loop                                 -- druga połowa: wartości 0..3 — dużo remisów
        if k < 500 then
          v((i + 1) * W - 1 downto i * W) := std_logic_vector(to_unsigned(rnd(2 ** W), W));
        else
          v((i + 1) * W - 1 downto i * W) := std_logic_vector(to_unsigned(rnd(4), W));
        end if;
      end loop;
      x <= v;  wait for 1 ns;  check;
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
