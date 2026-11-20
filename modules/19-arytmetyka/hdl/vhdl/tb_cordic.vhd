-- Testbench cordic (19.04), W = 16, A = 24, N = 18, dane w każdym takcie:
--   obrót: sin/cos dla 4096 kątów z całego okręgu i 4000 losowych wektorów i kątów,
--   wektorowanie: K·|v| i atan2(y, x) (dla |v| >= 2^12), y_out ≈ 0.
-- Tolerancje: 3 LSB (sin/cos), 4 LSB (obrót, moduł), 256 LSB kąta (2^24 na obrót).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_cordic is
end entity tb_cordic;

architecture sim of tb_cordic is
  constant W  : positive := 16;
  constant A  : positive := 24;
  constant N  : positive := 18;
  constant NPROB : positive := 4096 + 4000;
  constant TOL_KAT : real := 256.0;
  type h_t is array (0 to NPROB - 1) of integer;
  signal clk      : std_logic := '0';
  signal fin      : boolean := false;
  signal in_valid : std_logic := '0';
  signal x_in, y_in : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal z_in     : std_logic_vector(A - 1 downto 0) := (others => '0');
  signal vr, vv   : std_logic;
  signal xr, yr, xv, yv : std_logic_vector(W + 1 downto 0);
  signal zr, zv   : std_logic_vector(A - 1 downto 0);
  signal hx, hy, hz, ht : h_t;
  signal takt, no, errors : integer := 0;
  signal m_sc, m_obr, m_mod, m_kat : real := 0.0;

  function wzmocnienie return real is
    variable k : real := 1.0;
  begin
    for i in 0 to N - 1 loop k := k * sqrt(1.0 + 2.0 ** (-2 * i)); end loop;
    return k;
  end function;
  constant K : real := wzmocnienie;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);

  u_obr : entity work.cordic generic map (W => W, A => A, N => N, G => 4, TRYB => 0)
    port map (clk, in_valid, x_in, y_in, z_in, vr, xr, yr, zr);
  u_wek : entity work.cordic generic map (W => W, A => A, N => N, G => 4, TRYB => 1)
    port map (clk, in_valid, x_in, y_in, (A - 1 downto 0 => '0'), vv, xv, yv, zv);

  process (clk)
    variable th, ex, ey, er, ekat, d, dk : real;
    variable bl : integer;
  begin
    if rising_edge(clk) and vr = '1' then
      bl := 0;
      if vv /= '1' or takt - ht(no) /= N + 2 then bl := bl + 1; end if;
      th := real(hz(no)) * MATH_2_PI / 2.0 ** A;
      ex := K * (real(hx(no)) * cos(th) - real(hy(no)) * sin(th));
      ey := K * (real(hx(no)) * sin(th) + real(hy(no)) * cos(th));
      d  := maximum(abs(real(to_integer(signed(xr))) - ex), abs(real(to_integer(signed(yr))) - ey));
      if no < 4096 then
        m_sc <= maximum(m_sc, d);
        if d > 3.0 then bl := bl + 1; end if;
      else
        m_obr <= maximum(m_obr, d);
        if d > 4.0 then bl := bl + 1; end if;
      end if;
      er := K * sqrt(real(hx(no)) ** 2 + real(hy(no)) ** 2);
      d  := abs(real(to_integer(signed(xv))) - er);
      m_mod <= maximum(m_mod, d);
      if d > 4.0 or abs(to_integer(signed(yv))) > 4 then bl := bl + 1; end if;
      if er >= K * 4096.0 then
        ekat := arctan(real(hy(no)), real(hx(no))) / MATH_2_PI * 2.0 ** A;
        dk   := real(to_integer(signed(zv))) - ekat;
        if dk >= 2.0 ** (A - 1) then dk := dk - 2.0 ** A; end if;
        if dk < -2.0 ** (A - 1) then dk := dk + 2.0 ** A; end if;
        m_kat <= maximum(m_kat, abs(dk));
        if abs(dk) > TOL_KAT then bl := bl + 1; end if;
      end if;
      errors <= errors + bl;
      no <= no + 1;
    end if;
  end process;

  process
    variable l : line;
    variable s1, s2 : positive := 11;
    variable r : real;
    variable xi, yi, zi : integer;
  begin
    wait for 25 ns;
    for i in 0 to NPROB - 1 loop
      wait until falling_edge(clk);
      if i < 4096 then
        xi := integer(round(32767.0 / K));
        yi := 0;
        uniform(s1, s2, r);
        zi := i * 2 ** (A - 12) + integer(floor(r * 2.0 ** (A - 12)));
      else
        uniform(s1, s2, r); xi := integer(floor(r * 65536.0)) - 32768;
        uniform(s1, s2, r); yi := integer(floor(r * 65536.0)) - 32768;
        uniform(s1, s2, r); zi := integer(floor(r * 2.0 ** A));
      end if;
      if zi >= 2 ** (A - 1) then zi := zi - 2 ** A; end if;       -- kąt ze znakiem
      x_in <= std_logic_vector(to_signed(xi, W));
      y_in <= std_logic_vector(to_signed(yi, W));
      z_in <= std_logic_vector(to_signed(zi, A));
      in_valid <= '1';
      hx(i) <= xi; hy(i) <= yi; hz(i) <= zi; ht(i) <= takt;
    end loop;
    wait until falling_edge(clk);
    in_valid <= '0';
    for i in 1 to N + 6 loop wait until falling_edge(clk); end loop;
    write(l, "K = " & real'image(K) & "; najwiekszy blad: sin/cos " & real'image(m_sc) & " LSB, obrot "
          & real'image(m_obr) & " LSB, modul " & real'image(m_mod) & " LSB, kat " & real'image(m_kat) & " LSB");
    writeline(output, l);
    if errors = 0 and no = NPROB then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow, wynikow " & integer'image(no)); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
