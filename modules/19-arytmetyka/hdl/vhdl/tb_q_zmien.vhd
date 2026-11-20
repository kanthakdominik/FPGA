-- Testbench q_zmien (19.01): wszystkie wejścia kilku konfiguracji, model na liczbach całkowitych.
--   A: Q8.8 -> Q4.4 (obcięcie, połówka w górę, zbieżne; zbieżne z zawijaniem), B: Q7.1 -> Q8.0 zbieżne,
--   C: Q4.4 -> Q8.8 (bez zaokrąglania), D: Q4.4 (8 b) -> Q0.4 (4 b) — samo nasycenie.
-- Średni błąd sposobów zaokrąglania dla A: obcięcie -0,46875, połówka w górę +0,03125, zbieżne 0 LSB.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_q_zmien is
end entity tb_q_zmien;

architecture sim of tb_q_zmien is
  signal xa                    : std_logic_vector(15 downto 0) := (others => '0');
  signal xb                    : std_logic_vector(7 downto 0)  := (others => '0');
  signal ya0, ya1, ya2, ya3, yb : std_logic_vector(7 downto 0);
  signal yc                    : std_logic_vector(15 downto 0);
  signal yd                    : std_logic_vector(3 downto 0);
  signal pa0, pa1, pa2, pa3, pb, pc, pd : std_logic;

  -- model: d — usuwane bity ułamkowe (ujemne: dopisywane), tryb zaokrąglania, wo — bity wyjścia
  procedure model(x : integer; d : integer; tryb : natural; wo : positive; nasyc : boolean;
                  variable y : out integer; variable p : out boolean) is
    variable podl, reszta, pol, t, maks, mini : integer;
  begin
    if d > 0 then
      podl   := x / 2 ** d;
      if x < 0 and podl * 2 ** d /= x then podl := podl - 1; end if;    -- podłoga dla ujemnych
      reszta := x - podl * 2 ** d;
      pol    := 2 ** (d - 1);
      if tryb = 0 then
        t := podl;
      elsif tryb = 1 then
        t := podl + 1 when reszta >= pol else podl;
      else
        t := podl + 1 when reszta > pol or (reszta = pol and podl mod 2 /= 0) else podl;
      end if;
    else
      t := x * 2 ** (-d);
    end if;
    maks := 2 ** (wo - 1) - 1;
    mini := -2 ** (wo - 1);
    p := t > maks or t < mini;
    if t <= maks and t >= mini then
      y := t;
    elsif nasyc then
      y := maks when t > maks else mini;
    else
      y := t mod 2 ** wo;
      if y > maks then y := y - 2 ** wo; end if;
    end if;
  end procedure;
begin
  ua0 : entity work.q_zmien generic map (16, 8, 8, 4, 0, true)  port map (xa, ya0, pa0);
  ua1 : entity work.q_zmien generic map (16, 8, 8, 4, 1, true)  port map (xa, ya1, pa1);
  ua2 : entity work.q_zmien generic map (16, 8, 8, 4, 2, true)  port map (xa, ya2, pa2);
  ua3 : entity work.q_zmien generic map (16, 8, 8, 4, 2, false) port map (xa, ya3, pa3);
  ub  : entity work.q_zmien generic map (8, 1, 8, 0, 2, true)   port map (xb, yb, pb);
  uc  : entity work.q_zmien generic map (8, 4, 16, 8, 2, true)  port map (xb, yc, pc);
  ud  : entity work.q_zmien generic map (8, 4, 4, 4, 2, true)   port map (xb, yd, pd);

  process
    variable l : line;
    variable errors, x, y, n_bez, n_prz : integer := 0;
    variable prz : boolean;
    variable b0, b1, b2, sr0, sr1, sr2 : real := 0.0;

    procedure sprawdz(nazwa : string; wynik : std_logic_vector; p_dut : std_logic; oczek : integer; p_o : boolean) is
    begin
      if to_integer(signed(wynik)) /= oczek or (p_dut = '1') /= p_o then
        if errors < 10 then
          write(l, nazwa & " x=" & integer'image(x) & ": " & integer'image(to_integer(signed(wynik)))
                & ", oczekiwano " & integer'image(oczek));
          writeline(output, l);
        end if;
        errors := errors + 1;
      end if;
    end procedure;
  begin
    for i in 0 to 65535 loop
      xa <= std_logic_vector(to_unsigned(i, 16));
      xb <= std_logic_vector(to_unsigned(i mod 256, 8));
      wait for 1 ns;
      x := to_integer(signed(xa));
      model(x, 4, 0, 8, true, y, prz);  sprawdz("A0", ya0, pa0, y, prz);
      if not prz then b0 := b0 + real(y * 16 - x); end if;
      model(x, 4, 1, 8, true, y, prz);  sprawdz("A1", ya1, pa1, y, prz);
      if not prz then b1 := b1 + real(y * 16 - x); end if;
      model(x, 4, 2, 8, true, y, prz);  sprawdz("A2", ya2, pa2, y, prz);
      if not prz then b2 := b2 + real(y * 16 - x); n_bez := n_bez + 1; else n_prz := n_prz + 1; end if;
      model(x, 4, 2, 8, false, y, prz); sprawdz("A3", ya3, pa3, y, prz);
      if i < 256 then
        x := to_integer(signed(xb));
        model(x, 1, 2, 8, true, y, prz);   sprawdz("B", yb, pb, y, prz);
        model(x, -4, 2, 16, true, y, prz); sprawdz("C", yc, pc, y, prz);
        model(x, 0, 2, 4, true, y, prz);   sprawdz("D", yd, pd, y, prz);
      end if;
    end loop;
    sr0 := b0 / real(n_bez * 16);
    sr1 := b1 / real(n_bez * 16);
    sr2 := b2 / real(n_bez * 16);
    write(l, "A: " & integer'image(n_bez) & " wartosci w zakresie, " & integer'image(n_prz)
          & " nasyconych; sredni blad [LSB]: obciecie " & real'image(sr0) & ", polowka w gore "
          & real'image(sr1) & ", zbiezne " & real'image(sr2));
    writeline(output, l);
    if sr0 > -0.46 or sr0 < -0.48 or sr1 < 0.025 or sr1 > 0.04 or abs(sr2) > 0.005 then
      errors := errors + 1;
    end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    std.env.finish;
    wait;
  end process;
end architecture sim;
