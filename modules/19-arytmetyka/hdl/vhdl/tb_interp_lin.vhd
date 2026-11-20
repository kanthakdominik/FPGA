-- Testbench interp_lin (19.06): wszystkie 65 536 wejść strumieniem, porównanie z sin(πx/2)·2^16
-- (nasycone do 65535), tolerancja 4 LSB; największy i średni błąd, opóźnienie 3 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_interp_lin is
end entity tb_interp_lin;

architecture sim of tb_interp_lin is
  constant TOL : real := 4.0;
  signal clk       : std_logic := '0';
  signal fin       : boolean := false;
  signal in_valid  : std_logic := '0';
  signal x, y      : std_logic_vector(15 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal takt, t0, k, errors : integer := 0;
  signal m, suma   : real := 0.0;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);
  dut : entity work.interp_lin port map (clk => clk, in_valid => in_valid, x => x, out_valid => out_valid, y => y);

  process (clk)
    variable w, d : real;
  begin
    if rising_edge(clk) and out_valid = '1' then
      w := minimum(sin(MATH_PI * real(k) / 131072.0) * 65536.0, 65535.0);
      d := abs(real(to_integer(unsigned(y))) - w);
      m    <= maximum(m, d);
      suma <= suma + d;
      if d > TOL or takt - (t0 + k) /= 3 then errors <= errors + 1; end if;
      k <= k + 1;
    end if;
  end process;

  process
    variable l : line;
  begin
    wait for 25 ns;
    wait until falling_edge(clk);
    t0 <= takt;
    for i in 0 to 65535 loop
      x <= std_logic_vector(to_unsigned(i, 16));
      in_valid <= '1';
      wait until falling_edge(clk);
    end loop;
    in_valid <= '0';
    for i in 1 to 5 loop wait until falling_edge(clk); end loop;
    write(l, "wynikow " & integer'image(k) & ", najwiekszy blad " & real'image(m) & " LSB, sredni "
          & real'image(suma / real(k)) & " LSB");
    writeline(output, l);
    if errors = 0 and k = 65536 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
