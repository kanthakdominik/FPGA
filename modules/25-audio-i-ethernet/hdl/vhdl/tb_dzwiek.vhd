-- Testbench 25.02: biquad (dolnoprzepustowy fc = 1 kHz, Q = 0,707, f_pr = 48 828 Hz, współczynniki RBJ skwantowane
-- w testbenchu) — 3000 losowych próbek bit w bit z modelem i odpowiedź na sinusy 200 Hz, 1 kHz, 5 kHz; echo
-- (D = 100, g = 128) — odpowiedź impulsowa i 3000 losowych próbek bit w bit z modelem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_dzwiek is
end entity tb_dzwiek;

architecture sim of tb_dzwiek is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal we, ewe, y_w, ey_w : std_logic := '0';
  signal x, ex, y, ey : signed(23 downto 0) := (others => '0');
  signal b0, b1, b2, a1, a2 : signed(17 downto 0) := (others => '0');
begin
  clk <= not clk after 40 ns when not fin else clk;

  u_bq : entity work.biquad
    port map (clk => clk, rst => rst, we => we, x => x, b0 => b0, b1 => b1, b2 => b2, a1 => a1, a2 => a2,
              y => y, y_wazne => y_w);
  u_echo : entity work.echo
    generic map (D => 100)
    port map (clk => clk, rst => rst, we => ewe, x => ex, g => to_unsigned(128, 8), y => ey, y_wazne => ey_w);

  process
    variable l : line;
    variable errors, bl_bq, bl_ec, maks, n_ec : integer := 0;
    variable s1, s2 : positive := 7;
    variable r, f_pr, w0, al, ka0, gdb, fsin : real;
    variable mx1, mx2, my1, my2, acc, w, k : integer := 0;
    variable xm : integer;
    type hist_t is array (0 to 99) of integer;
    variable hist : hist_t := (others => 0);
    variable ep : natural := 0;
    variable ib0, ib1, ib2, ia1, ia2 : integer;
    variable racc : real;

    -- model biquad na liczbach rzeczywistych podwójnej precyzji: iloczyny 18 × 24 bity i suma < 2^53 są dokładne
    impure function model_bq(xx : integer) return integer is
      variable a, q : real;
      variable v : integer;
    begin
      a := real(ib0) * real(xx) + real(ib1) * real(mx1) + real(ib2) * real(mx2) - real(ia1) * real(my1)
           - real(ia2) * real(my2);
      q := floor((a + 32768.0) / 65536.0);
      if q > 8388607.0 then q := 8388607.0; end if;
      if q < -8388608.0 then q := -8388608.0; end if;
      v := integer(q);
      return v;
    end function;

    procedure probka(v : integer) is
    begin
      wait until falling_edge(clk);
      x <= to_signed(v, 24); we <= '1';
      wait until falling_edge(clk);
      we <= '0';
      wait until y_w = '1';
      wait for 1 ns;
    end procedure;
    procedure eprobka(v : integer) is
    begin
      wait until falling_edge(clk);
      ex <= to_signed(v, 24); ewe <= '1';
      wait until falling_edge(clk);
      ewe <= '0';
      wait until ey_w = '1';
      wait for 1 ns;
    end procedure;
    impure function model_ec(xx, stara : integer) return integer is
      variable s, q : integer;
    begin
      q := integer(floor(real(stara) / 256.0));                    -- w pamięci 16 starszych bitów
      s := xx + q * 128;                                           -- (q·256)·128/256
      if s > 8388607 then s := 8388607; end if;
      if s < -8388608 then s := -8388608; end if;
      return s;
    end function;
    procedure los24(v : out integer) is
    begin
      uniform(s1, s2, r);
      v := integer(floor(r * 16777216.0)) - 8388608;
    end procedure;
  begin
    f_pr := 12500000.0 / 256.0;
    w0 := 2.0 * MATH_PI * 1000.0 / f_pr;
    al := sin(w0) / (2.0 * 0.7071);
    ka0 := 1.0 + al;
    ib0 := integer(floor((1.0 - cos(w0)) / 2.0 / ka0 * 65536.0 + 0.5));
    ib1 := integer(floor((1.0 - cos(w0)) / ka0 * 65536.0 + 0.5));
    ib2 := ib0;
    ia1 := -integer(floor(2.0 * cos(w0) / ka0 * 65536.0 + 0.5));
    ia2 := integer(floor((1.0 - al) / ka0 * 65536.0 + 0.5));
    b0 <= to_signed(ib0, 18); b1 <= to_signed(ib1, 18); b2 <= to_signed(ib2, 18);
    a1 <= to_signed(ia1, 18); a2 <= to_signed(ia2, 18);
    write(l, "wspolczynniki Q2.16: b0 = " & integer'image(ib0) & ", b1 = " & integer'image(ib1) & ", b2 = "
          & integer'image(ib2) & ", a1 = " & integer'image(ia1) & ", a2 = " & integer'image(ia2));
    writeline(output, l);
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    -- 1. losowe
    for n in 0 to 2999 loop
      los24(xm);
      k := model_bq(xm);
      probka(xm);
      if to_integer(y) /= k then bl_bq := bl_bq + 1; end if;
      mx2 := mx1; mx1 := xm; my2 := my1; my1 := k;
    end loop;
    write(l, "biquad: 3000 losowych probek, niezgodnych z modelem " & integer'image(bl_bq));
    writeline(output, l);
    if bl_bq /= 0 then errors := errors + 1; end if;
    -- 2. sinusy
    for f in 0 to 2 loop
      if f = 0 then fsin := 200.0; elsif f = 1 then fsin := 1000.0; else fsin := 5000.0; end if;
      maks := 0;
      for n in 0 to 2399 loop
        xm := integer(floor(4194304.0 * sin(2.0 * MATH_PI * fsin * real(n) / f_pr)));
        k := model_bq(xm);
        probka(xm);
        mx2 := mx1; mx1 := xm; my2 := my1; my1 := k;
        if n >= 1200 and to_integer(y) > maks then maks := to_integer(y); end if;
      end loop;
      gdb := 20.0 * log10(real(maks) / 4194304.0);
      write(l, "sinus " & integer'image(integer(fsin)) & " Hz: amplituda wyjscia " & integer'image(maks)
            & ", wzmocnienie " & integer'image(integer(gdb * 100.0)) & "/100 dB");
      writeline(output, l);
      if f = 0 and abs gdb > 0.5 then errors := errors + 1; end if;
      if f = 1 and (gdb > -2.0 or gdb < -4.0) then errors := errors + 1; end if;
      if f = 2 and gdb > -20.0 then errors := errors + 1; end if;
    end loop;
    -- 3. echo: impuls
    eprobka(4194304);
    if to_integer(ey) /= 4194304 then errors := errors + 1; end if;
    hist(0) := to_integer(ey); ep := 1;
    for n in 1 to 300 loop
      eprobka(0);
      if (n = 100 and to_integer(ey) /= 2097152) or (n = 200 and to_integer(ey) /= 1048576)
         or (n = 300 and to_integer(ey) /= 524288) or (n mod 100 /= 0 and to_integer(ey) /= 0) then
        bl_ec := bl_ec + 1;
      end if;
      hist(ep mod 100) := to_integer(ey); ep := ep + 1;
    end loop;
    write(l, "echo: odpowiedz impulsowa (1, 1/2, 1/4, 1/8 co 100 probek), bledow " & integer'image(bl_ec));
    writeline(output, l);
    -- 4. echo: losowe
    for n in 0 to 2999 loop
      los24(xm);
      k := model_ec(xm, hist(ep mod 100));
      eprobka(xm);
      if to_integer(ey) /= k then bl_ec := bl_ec + 1; end if;
      hist(ep mod 100) := to_integer(ey); ep := ep + 1;
    end loop;
    write(l, "echo: razem bledow " & integer'image(bl_ec) & " (z 3000 losowymi probkami)");
    writeline(output, l);
    if bl_ec /= 0 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
