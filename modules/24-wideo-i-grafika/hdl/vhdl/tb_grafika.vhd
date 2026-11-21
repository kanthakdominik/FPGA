-- Testbench 24.03: linia_bres (12 odcinków szczególnych i 300 losowych, odbiorca wstrzymuje w 30% taktów:
-- końce, liczba punktów, kroki, odległość od prostej ≤ 1/2), znaki (napis "ABC 0123?" i "a"; piksele A, 1, a
-- porównane z rysunkiem, odstępy i komórki puste — zera), sprite16 (obszar 24×24 przy (100, 50) i przy (0, 0)).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_grafika is
end entity tb_grafika;

architecture sim of tb_grafika is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  -- linia
  signal start, dalej : std_logic := '0';
  signal x0, y0, x1, y1 : unsigned(11 downto 0) := (others => '0');
  signal gotowy, pwazny, koniec : std_logic;
  signal px, py : unsigned(11 downto 0);
  -- znaki i sprite
  signal we : std_logic := '0';
  signal wadr : unsigned(10 downto 0) := (others => '0');
  signal wkod : std_logic_vector(7 downto 0) := x"00";
  signal x, y : unsigned(11 downto 0) := (others => '0');
  signal sx : unsigned(11 downto 0) := to_unsigned(100, 12);
  signal sy : unsigned(11 downto 0) := to_unsigned(50, 12);
  signal piks, widoczny : std_logic;
  signal kolor : std_logic_vector(1 downto 0);

  type rys5_t is array (0 to 6) of string(1 to 5);
  constant LIT_A : rys5_t := (" ### ", "#   #", "#   #", "#####", "#   #", "#   #", "#   #");
  constant CYF_1 : rys5_t := ("  #  ", " ##  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### ");
  type rys16_t is array (0 to 15) of string(1 to 16);
  constant OBRAZ : rys16_t := (
     0 => ".....aaaaaa.....",
     1 => "...aabbbbbbaa...",
     2 => "..abbbbbbbbbba..",
     3 => ".abbbbbbbbbbbba.",
     4 => ".abbcccbbcccbba.",
     5 => "abbbcacbbcacbbba",
     6 => "abbbcccbbcccbbba",
     7 => "abbbbbbbbbbbbbba",
     8 => "abbbbbbbbbbbbbba",
     9 => "abbcbbbbbbbbcbba",
    10 => "abbbcbbbbbbcbbba",
    11 => ".abbbccccccbbba.",
    12 => ".abbbbbbbbbbbba.",
    13 => "..abbbbbbbbbba..",
    14 => "...aabbbbbbaa...",
    15 => ".....aaaaaa....."
  );

  -- stan sprawdzania odcinków (wspólny dla procesu odbioru i procesu sterującego)
  signal ax0, ay0, ax1, ay1, ddx, ddy, gl : integer := 0;
  signal n_pkt, wiersz_bl, takty : natural := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_lin : entity work.linia_bres
    port map (clk => clk, rst => rst, start => start, x0 => x0, y0 => y0, x1 => x1, y1 => y1, dalej => dalej,
              gotowy => gotowy, px => px, py => py, pwazny => pwazny, koniec => koniec);
  u_zn : entity work.znaki
    generic map (KOL => 40, WIER => 30, SK => 1)
    port map (clk => clk, we => we, wadr => wadr, wkod => wkod, x => x, y => y, piks => piks);
  u_sp : entity work.sprite16
    port map (clk => clk, x => x, y => y, sx => sx, sy => sy, widoczny => widoczny, kolor => kolor);

  -- odbiorca punktów: losowe wstrzymanie i kontrola
  process (clk)
    variable s1, s2 : positive := 2024;
    variable r : real;
    variable qx, qy, pop_x, pop_y, b, m, maj : integer := 0;
    variable pierwszy : boolean := false;
  begin
    if falling_edge(clk) then
      uniform(s1, s2, r);
      if r < 0.7 then dalej <= '1'; else dalej <= '0'; end if;
    end if;
    if rising_edge(clk) then
      if gotowy = '0' then takty <= takty + 1; end if;
      if start = '1' and gotowy = '1' then pierwszy := true; end if;
      if pwazny = '1' and dalej = '1' then
        b := 0;
        qx := to_integer(px); qy := to_integer(py);
        if pierwszy then
          if qx /= ax0 or qy /= ay0 then b := b + 1; end if;
        else
          if abs (qx - pop_x) > 1 or abs (qy - pop_y) > 1 then b := b + 1; end if;
          if gl = 0 and qx = pop_x then b := b + 1; end if;
          if gl = 1 and qy = pop_y then b := b + 1; end if;
        end if;
        if gl = 0 then
          m := 2 * ((qy - ay0) * ddx - (qx - ax0) * ddy); maj := abs ddx;
        else
          m := 2 * ((qx - ax0) * ddy - (qy - ay0) * ddx); maj := abs ddy;
        end if;
        if abs m > maj then b := b + 1; end if;
        if koniec = '1' and (qx /= ax1 or qy /= ay1) then b := b + 1; end if;
        pop_x := qx; pop_y := qy;
        pierwszy := false;
        n_pkt <= n_pkt + 1;
        wiersz_bl <= wiersz_bl + b;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable s1, s2 : positive := 99;
    variable r : real;
    variable errors, bl_lin, n_lin, n0 : natural := 0;
    variable bl_zn, n_zn, n_jas, bl_sp, n_sp, n_wid : natural := 0;
    variable cx, cy, fx, fy, ox, oy : integer;
    variable ocz : std_logic;
    variable okol : natural;
    constant NAPIS : string(1 to 9) := "ABC 0123?";

    function los(n : natural; v : real) return natural is
    begin
      return integer(floor(v * real(n))) mod n;
    end function;

    procedure odcinek(a, bb, c, d : natural) is
      variable ile, wb0 : natural;
    begin
      ax0 <= a; ay0 <= bb; ax1 <= c; ay1 <= d; ddx <= c - a; ddy <= d - bb;
      if abs (c - a) >= abs (d - bb) then gl <= 0; ile := abs (c - a) + 1; else gl <= 1; ile := abs (d - bb) + 1; end if;
      wait until falling_edge(clk);
      n0 := n_pkt; wb0 := wiersz_bl;
      x0 <= to_unsigned(a, 12); y0 <= to_unsigned(bb, 12); x1 <= to_unsigned(c, 12); y1 <= to_unsigned(d, 12);
      start <= '1';
      wait until falling_edge(clk);
      start <= '0';
      wait until gotowy = '1';
      wait until falling_edge(clk);
      if n_pkt - n0 /= ile or wiersz_bl /= wb0 then
        if bl_lin < 5 then
          write(l, "odcinek (" & integer'image(a) & "," & integer'image(bb) & ")-(" & integer'image(c) & ","
                & integer'image(d) & "): " & integer'image(wiersz_bl - wb0) & " bledow, " & integer'image(n_pkt - n0)
                & " punktow");
          writeline(output, l);
        end if;
        bl_lin := bl_lin + 1;
      end if;
      n_lin := n_lin + 1;
    end procedure;

    function rys(w : string; kol : natural) return std_logic is
    begin
      if w(kol + 1) = '#' then return '1'; else return '0'; end if;
    end function;

    procedure piksel_znaku(xx, yy : natural) is
    begin
      wait until falling_edge(clk);
      x <= to_unsigned(xx, 12); y <= to_unsigned(yy, 12);
      wait until rising_edge(clk);
      wait until rising_edge(clk);
      wait for 1 ns;
      cx := xx / 16; cy := yy / 16; fx := (xx / 2) mod 8; fy := (yy / 2) mod 8;
      ocz := '0';
      if fx < 5 and fy < 7 and cy = 2 and cx = 3 then ocz := rys(LIT_A(fy), fx); end if;
      if fx < 5 and fy < 7 and cy = 2 and cx = 8 then ocz := rys(CYF_1(fy), fx); end if;
      if fx < 5 and fy < 7 and cy = 5 and cx = 0 then ocz := rys(LIT_A(fy), fx); end if;
      if fx < 5 and fy < 7 and cy = 2 and cx >= 4 and cx <= 11 and cx /= 8 then ocz := piks; end if;
      if piks /= ocz then
        if bl_zn < 5 then
          write(l, "tekst: piksel (" & integer'image(xx) & "," & integer'image(yy) & ") = " & std_logic'image(piks));
          writeline(output, l);
        end if;
        bl_zn := bl_zn + 1;
      end if;
      n_zn := n_zn + 1;
      if piks = '1' then n_jas := n_jas + 1; end if;
    end procedure;

    procedure piksel_sprite(xx, yy : natural) is
      variable ch : character;
    begin
      wait until falling_edge(clk);
      x <= to_unsigned(xx, 12); y <= to_unsigned(yy, 12);
      wait until rising_edge(clk);
      wait for 1 ns;
      ox := xx - to_integer(sx); oy := yy - to_integer(sy);
      okol := 0;
      if ox >= 0 and ox < 16 and oy >= 0 and oy < 16 then
        ch := OBRAZ(oy)(ox + 1);
        case ch is
          when 'a' => okol := 1;
          when 'b' => okol := 2;
          when 'c' => okol := 3;
          when others => okol := 0;
        end case;
      end if;
      if (widoczny = '1') /= (okol /= 0) or (widoczny = '1' and to_integer(unsigned(kolor)) /= okol) then
        if bl_sp < 5 then
          write(l, "sprite: (" & integer'image(xx) & "," & integer'image(yy) & ") widoczny " & std_logic'image(widoczny)
                & ", oczekiwano " & integer'image(okol));
          writeline(output, l);
        end if;
        bl_sp := bl_sp + 1;
      end if;
      n_sp := n_sp + 1;
      if widoczny = '1' then n_wid := n_wid + 1; end if;
    end procedure;

    variable a, bb, c, d : natural;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    odcinek(10, 10, 10, 10);   odcinek(0, 0, 639, 0);     odcinek(639, 479, 0, 479); odcinek(5, 0, 5, 479);
    odcinek(5, 479, 5, 0);     odcinek(0, 0, 479, 479);   odcinek(479, 0, 0, 479);   odcinek(100, 100, 107, 103);
    odcinek(100, 100, 93, 97); odcinek(100, 100, 103, 107); odcinek(100, 100, 97, 93); odcinek(320, 240, 0, 1);
    for i in 1 to 300 loop
      uniform(s1, s2, r); a := los(640, r);
      uniform(s1, s2, r); bb := los(480, r);
      uniform(s1, s2, r); c := los(640, r);
      uniform(s1, s2, r); d := los(480, r);
      odcinek(a, bb, c, d);
    end loop;
    write(l, "odcinki: " & integer'image(n_lin) & ", punktow " & integer'image(n_pkt) & " w " & integer'image(takty)
          & " taktach (odbiorca gotowy w 70% taktow), bledne odcinki " & integer'image(bl_lin));
    writeline(output, l);
    if bl_lin /= 0 then errors := errors + 1; end if;

    for i in 0 to 8 loop
      wait until falling_edge(clk);
      we <= '1'; wadr <= to_unsigned(2 * 40 + 3 + i, 11);
      wkod <= std_logic_vector(to_unsigned(character'pos(NAPIS(i + 1)), 8));
    end loop;
    wait until falling_edge(clk);
    wadr <= to_unsigned(5 * 40, 11); wkod <= std_logic_vector(to_unsigned(character'pos('a'), 8));
    wait until falling_edge(clk);
    we <= '0';
    for j in 2 * 16 to 3 * 16 - 1 loop
      for i in 2 * 16 to 13 * 16 - 1 loop piksel_znaku(i, j); end loop;
    end loop;
    for j in 5 * 16 to 6 * 16 - 1 loop
      for i in 0 to 2 * 16 - 1 loop piksel_znaku(i, j); end loop;
    end loop;
    write(l, "tekst: " & integer'image(n_zn) & " pikseli sprawdzonych, " & integer'image(n_jas) & " jasnych, bledow "
          & integer'image(bl_zn));
    writeline(output, l);
    if bl_zn /= 0 or n_jas = 0 then errors := errors + 1; end if;

    for j in 46 to 69 loop
      for i in 96 to 119 loop piksel_sprite(i, j); end loop;
    end loop;
    wait until falling_edge(clk);
    sx <= (others => '0'); sy <= (others => '0');
    for j in 0 to 19 loop
      for i in 0 to 19 loop piksel_sprite(i, j); end loop;
    end loop;
    write(l, "sprite: " & integer'image(n_sp) & " pikseli sprawdzonych, " & integer'image(n_wid) & " widocznych, bledow "
          & integer'image(bl_sp));
    writeline(output, l);
    if bl_sp /= 0 or n_wid = 0 then errors := errors + 1; end if;

    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
