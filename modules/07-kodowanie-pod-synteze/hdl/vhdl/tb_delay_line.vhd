-- Testbench delay_line (DEPTH = 16 i 2): losowe dane i losowe ce, model — historia przyjętych próbek.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_delay_line is
end entity tb_delay_line;

architecture sim of tb_delay_line is
  signal clk           : std_logic := '0';
  signal done          : boolean   := false;
  signal ce            : std_logic := '0';
  signal din           : std_logic_vector(7 downto 0) := x"00";
  signal dout16, dout2 : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  u_d16 : entity work.delay_line generic map (W => 8, DEPTH => 16) port map (clk => clk, ce => ce, din => din, dout => dout16);
  u_d2  : entity work.delay_line generic map (W => 8, DEPTH => 2)  port map (clk => clk, ce => ce, din => din, dout => dout2);

  stim : process
    type hist_t is array (0 to 511) of std_logic_vector(7 downto 0);
    variable hist         : hist_t;                            -- próbki przyjęte przy ce = '1', w kolejności
    variable accepted     : natural  := 0;
    variable holds        : natural  := 0;
    variable errors       : natural  := 0;
    variable l            : line;
    variable seed1, seed2 : positive := 3;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure check;
  begin
    for n in 0 to 399 loop
      wait until falling_edge(clk);
      if ce = '1' then
        hist(accepted) := din;
        accepted       := accepted + 1;
      elsif n > 0 then
        holds := holds + 1;
      end if;
      if accepted >= 16 then
        check(dout16 = hist(accepted - 16), "dout16 w takcie " & integer'image(n));
      end if;
      if accepted >= 2 then
        check(dout2 = hist(accepted - 2), "dout2 w takcie " & integer'image(n));
      end if;
      if rnd(3) /= 0 then
        ce <= '1';
      else
        ce <= '0';
      end if;
      din <= std_logic_vector(to_unsigned(rnd(256), 8));
    end loop;

    check(holds > 0, "test nie sprawdzil wstrzymania (ce = 0)");
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
