-- Testbench bufor_linii: obraz 16 x 12, piksel(y, x) = (y * 16 + x) mod 256, strumień z losowymi przerwami.
-- Sprawdzane: p0 = piksel(y, x), p1 = piksel(y - 1, x), p2 = piksel(y - 2, x) (zera przed obrazem).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_bufor_linii is
end entity tb_bufor_linii;

architecture sim of tb_bufor_linii is
  constant W    : positive := 8;
  constant SZER : positive := 16;
  constant WYS  : positive := 12;
  signal clk, rst : std_logic := '1';
  signal in_valid, out_valid : std_logic := '0';
  signal piksel, p0, p1, p2 : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal n_out, errors_s : natural := 0;
  signal fin : boolean := false;

  function pix(y, x : integer) return natural is
  begin
    if y < 0 then
      return 0;
    end if;
    return (y * 16 + x) mod 256;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.bufor_linii generic map (W => W, SZER => SZER)
    port map (clk => clk, rst => rst, in_valid => in_valid, piksel => piksel, out_valid => out_valid,
              p0 => p0, p1 => p1, p2 => p2);

  process
    variable ox, oy : integer := 0;
    variable l : line;
  begin
    wait until rising_edge(clk);
    wait for 1 ns;
    if rst = '0' and out_valid = '1' then
      if to_integer(unsigned(p0)) /= pix(oy, ox) or to_integer(unsigned(p1)) /= pix(oy - 1, ox)
         or to_integer(unsigned(p2)) /= pix(oy - 2, ox) then
        write(l, "(" & integer'image(oy) & "," & integer'image(ox) & "): niezgodna kolumna"); writeline(output, l);
        errors_s <= errors_s + 1;
      end if;
      n_out <= n_out + 1;
      ox := ox + 1;
      if ox = SZER then ox := 0; oy := oy + 1; end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 31;
    variable r : real;
    variable l : line;
    variable x, y : integer := 0;
  begin
    wait for 23 ns;
    rst <= '0';
    while y < WYS loop
      wait until falling_edge(clk);
      uniform(s1, s2, r);
      if r < 0.67 then
        in_valid <= '1';
        piksel   <= std_logic_vector(to_unsigned(pix(y, x), W));
        x := x + 1;
        if x = SZER then x := 0; y := y + 1; end if;
      else
        in_valid <= '0';
      end if;
    end loop;
    wait until falling_edge(clk);
    in_valid <= '0';
    for k in 1 to 3 loop
      wait until falling_edge(clk);
    end loop;
    if errors_s = 0 and n_out = SZER * WYS then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors_s) & " bledow, " & integer'image(n_out) & " pikseli"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
