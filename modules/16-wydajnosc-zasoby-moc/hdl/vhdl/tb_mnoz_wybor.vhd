-- Testbench mnoz_wybor: obie wersje na tych samych danych; wynik = sel ? a*b : c*d po jednym takcie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_mnoz_wybor is
end entity tb_mnoz_wybor;

architecture sim of tb_mnoz_wybor is
  constant W : positive := 16;
  signal clk        : std_logic := '0';
  signal sel        : std_logic := '0';
  signal a, b, c, d : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal y0, y1     : std_logic_vector(2 * W - 1 downto 0);
  signal oczek      : unsigned(2 * W - 1 downto 0);
  signal fin        : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u0 : entity work.mnoz_wybor generic map (W => W, WSPOLNY => false)
    port map (clk => clk, sel => sel, a => a, b => b, c => c, d => d, y => y0);
  u1 : entity work.mnoz_wybor generic map (W => W, WSPOLNY => true)
    port map (clk => clk, sel => sel, a => a, b => b, c => c, d => d, y => y1);

  process (clk)
  begin
    if rising_edge(clk) then
      if sel = '1' then
        oczek <= unsigned(a) * unsigned(b);
      else
        oczek <= unsigned(c) * unsigned(d);
      end if;
    end if;
  end process;

  process
    variable s1, s2 : positive := 11;
    variable r      : real;
    variable l      : line;
    variable errors : integer := 0;
    impure function los return std_logic_vector is
    begin
      uniform(s1, s2, r);
      return std_logic_vector(to_unsigned(integer(floor(r * 65536.0)) mod 65536, W));
    end function;
  begin
    for n in 0 to 999 loop
      wait until falling_edge(clk);
      if n > 0 and (unsigned(y0) /= oczek or unsigned(y1) /= oczek) then
        write(l, "takt " & integer'image(n) & ": wyniki niezgodne z modelem"); writeline(output, l);
        errors := errors + 1;
      end if;
      a <= los; b <= los; c <= los; d <= los;
      uniform(s1, s2, r);
      if r < 0.125 then a <= (others => '1'); end if;
      uniform(s1, s2, r);
      if r < 0.125 then d <= (others => '1'); end if;
      uniform(s1, s2, r);
      if r < 0.5 then sel <= '1'; else sel <= '0'; end if;
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
