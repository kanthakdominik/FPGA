-- Testbench samosprawdzający mavg4: losowe pobudzenia, model referencyjny, tablica wyników (scoreboard)
-- i sprawdzenie pokrycia przypadków. Model liczy średnią na liczbach rzeczywistych z floor —
-- inaczej niż układ (shift_right na signed), więc ten sam błąd nie powtórzy się po obu stronach.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_mavg4 is
end entity tb_mavg4;

architecture sim of tb_mavg4 is
  signal clk       : std_logic := '0';
  signal done      : boolean   := false;
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal x         : signed(7 downto 0) := (others => '0');
  signal out_valid : std_logic;
  signal y         : signed(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.mavg4
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => out_valid, y => y);

  stim : process
    variable m1, m2, m3, m_y, s    : integer  := 0;           -- model referencyjny
    variable m_valid               : std_logic := '0';
    variable vx                    : integer;
    variable checked, errors       : natural  := 0;
    variable cov_floor, cov_min    : natural  := 0;
    variable cov_max, cov_hold     : natural  := 0;
    variable l                     : line;
    variable seed1, seed2          : positive := 71;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 2999 loop
      -- pobudzenia
      rst      <= '1' when n = 1500 else '0';                  -- jeden reset w trakcie pracy
      in_valid <= '1' when rnd(4) /= 0 else '0';
      if rnd(8) = 0 then
        vx := 127 when rnd(2) = 1 else -128;
      else
        vx := rnd(256) - 128;
      end if;
      x <= to_signed(vx, 8);
      wait until falling_edge(clk);
      -- model: stan po zboczu
      if rst = '1' then
        m1 := 0;  m2 := 0;  m3 := 0;  m_y := 0;  m_valid := '0';
      else
        m_valid := in_valid;
        if in_valid = '1' then
          s   := vx + m1 + m2 + m3;
          m_y := integer(floor(real(s) / 4.0));
          if s < 0 and s mod 4 /= 0 then
            cov_floor := cov_floor + 1;
          end if;
          m3 := m2;  m2 := m1;  m1 := vx;
        end if;
      end if;
      -- porównanie
      checked := checked + 1;
      if out_valid /= m_valid or to_integer(y) /= m_y then
        errors := errors + 1;
        report "takt " & integer'image(n) & ": y=" & integer'image(to_integer(y)) & ", model " & integer'image(m_y)
          severity warning;
      end if;
      if m_valid = '1' and m_y = -128 then cov_min := cov_min + 1; end if;
      if m_valid = '1' and m_y = 127 then cov_max := cov_max + 1; end if;
      if m_valid = '0' and rst = '0' then cov_hold := cov_hold + 1; end if;
    end loop;

    write(l, "sprawdzone takty: " & integer'image(checked) & ", pokrycie: zaokraglenie ujemnych "
           & integer'image(cov_floor) & ", y = -128: " & integer'image(cov_min) & ", y = 127: "
           & integer'image(cov_max) & ", wstrzymanie: " & integer'image(cov_hold));
    writeline(output, l);
    if cov_floor = 0 or cov_min = 0 or cov_max = 0 or cov_hold = 0 then
      errors := errors + 1;
      report "niepelne pokrycie przypadkow" severity warning;
    end if;
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
