-- Testbench shift_piso i shift_sipo połączonych szeregowo: bajt wpisany równolegle wychodzi bit po bicie
-- (od najstarszego) i po 8 przesunięciach pojawia się na wyjściu deserializatora. Przesunięcia z przerwami.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_shift is
end entity tb_shift;

architecture sim of tb_shift is
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  signal load  : std_logic := '0';
  signal shift : std_logic := '0';
  signal ser   : std_logic;
  signal din   : std_logic_vector(7 downto 0) := x"00";
  signal dout  : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  u_tx : entity work.shift_piso generic map (W => 8)
    port map (clk => clk, load => load, shift => shift, din => din, sout => ser);
  u_rx : entity work.shift_sipo generic map (W => 8)
    port map (clk => clk, shift => shift, sin => ser, dout => dout);

  stim : process
    variable errors       : natural  := 0;
    variable l            : line;
    variable seed1, seed2 : positive := 5;
    variable value        : std_logic_vector(7 downto 0);
    variable k            : natural;
    variable s            : std_logic;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;
  begin
    for n in 0 to 99 loop
      value := std_logic_vector(to_unsigned(rnd(256), 8));
      wait until falling_edge(clk);
      load <= '1';
      din  <= value;
      if n mod 2 = 1 then                                      -- co drugi bajt: load i shift razem
        shift <= '1';                                          -- load ma pierwszeństwo
      else
        shift <= '0';
      end if;
      wait until falling_edge(clk);
      load <= '0';
      k    := 0;
      while k < 8 loop
        if rnd(3) /= 0 then
          s := '1';
        else
          s := '0';
        end if;
        shift <= s;
        if ser /= value(7 - k) then
          errors := errors + 1;
          report "bajt " & integer'image(n) & " bit " & integer'image(7 - k) & ": zly bit" severity warning;
        end if;
        wait until falling_edge(clk);
        if s = '1' then
          k := k + 1;
        end if;
      end loop;
      shift <= '0';
      if dout /= value then
        errors := errors + 1;
        report "bajt " & integer'image(n) & ": dout=" & to_hstring(dout) & ", oczekiwano " & to_hstring(value)
          severity warning;
      end if;
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
