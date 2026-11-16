-- Testbench sine_rom: każdy adres porównany z wartością liczoną inaczej niż w układzie
-- (cos(pi/2 - x) zamiast sin x), sprawdzenie opóźnienia odczytu (1 takt) i monotoniczności ćwiartki.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_sine_rom is
end entity tb_sine_rom;

architecture sim of tb_sine_rom is
  signal clk  : std_logic := '0';
  signal done : boolean   := false;
  signal addr : std_logic_vector(5 downto 0) := (others => '0');
  signal data : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.sine_rom port map (clk => clk, addr => addr, data => data);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable prev   : natural := 0;
    variable e, got : natural;
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure check;
  begin
    wait until falling_edge(clk);
    for i in 0 to 63 loop
      addr <= std_logic_vector(to_unsigned(i, 6));
      wait for 1 ns;
      if i > 0 then                                            -- przed zboczem wyjście trzyma poprzednią wartość
        check(to_integer(unsigned(data)) = prev, "adres " & integer'image(i) & ": wyjscie zmienilo sie bez zbocza");
      end if;
      wait until falling_edge(clk);
      e   := integer(floor(255.0 * cos(MATH_PI_OVER_2 * (63.5 - real(i)) / 64.0) + 0.5));
      got := to_integer(unsigned(data));
      check(got = e, "adres " & integer'image(i) & ": data=" & integer'image(got) & ", oczekiwano " & integer'image(e));
      check(got >= prev, "adres " & integer'image(i) & ": tablica nie jest niemalejaca");
      prev := got;
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
