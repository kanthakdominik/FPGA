-- Testbench dzielenia i pierwiastka (19.03):
--   dziel_iter W = 8 bez znaku i ze znakiem — wszystkie pary; W = 16 — 3000 losowych i skrajnych,
--   dziel_potok W = 8 — wszystkie pary strumieniem, W = 16 — 5000 losowych,
--   pierw_iter W = 8 — wszystkie x 16-bitowe, W = 16 — 3000 losowych x 32-bitowych i kwadraty.
-- Wzorzec: / i rem (zaokrąglenie do zera, reszta ze znakiem dzielnej); przez zero — konwencja RISC-V.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_dzielenie is
end entity tb_dzielenie;

architecture sim of tb_dzielenie is
  signal clk  : std_logic := '0';
  signal fin  : boolean := false;
  signal rst  : std_logic := '1';
  signal takt : integer := 0;

  signal st8, st16 : std_logic := '0';
  signal a8, b8    : std_logic_vector(7 downto 0) := (others => '0');
  signal a16, b16  : std_logic_vector(15 downto 0) := (others => '0');
  signal bu8, du8, zu8, bs8, ds8, zs8, bu16, du16, zu16, bs16, ds16, zs16 : std_logic;
  signal qu8, ru8, qs8, rs8     : std_logic_vector(7 downto 0);
  signal qu16, ru16, qs16, rs16 : std_logic_vector(15 downto 0);

  signal pv8, pv16   : std_logic := '0';
  signal pa8, pb8    : std_logic_vector(7 downto 0) := (others => '0');
  signal pa16, pb16  : std_logic_vector(15 downto 0) := (others => '0');
  signal ov8, ov16   : std_logic;
  signal pq8, pr8    : std_logic_vector(7 downto 0);
  signal pq16, pr16  : std_logic_vector(15 downto 0);
  type h_t is array (natural range <>) of std_logic_vector(15 downto 0);
  signal gx, gy      : h_t(0 to 4999);
  signal t8          : integer := 0;      -- takt podania pierwszej pary (strumień W = 8 bez przerw)
  signal o8, o16, bl_pot : integer := 0;

  signal sp8, sp16   : std_logic := '0';
  signal x16         : std_logic_vector(15 downto 0) := (others => '0');
  signal x32         : std_logic_vector(31 downto 0) := (others => '0');
  signal pbz8, pd8, pbz16, pd16 : std_logic;
  signal pp8         : std_logic_vector(7 downto 0);
  signal prs8        : std_logic_vector(8 downto 0);
  signal pp16        : std_logic_vector(15 downto 0);
  signal prs16       : std_logic_vector(16 downto 0);

  -- oczekiwany iloraz i reszta jako W-bitowe słowa
  procedure oczek(w : positive; zn : boolean; x, y : std_logic_vector; variable q, r : out integer) is
    variable xi, yi, qi, ri : integer;
  begin
    if zn then xi := to_integer(signed(x)); yi := to_integer(signed(y));
    else xi := to_integer(unsigned(x)); yi := to_integer(unsigned(y)); end if;
    if yi = 0 then
      qi := -1; ri := xi;
    else
      qi := xi / yi; ri := xi rem yi;
    end if;
    q := qi mod 2 ** w;
    r := ri mod 2 ** w;
  end procedure;
begin
  clk  <= not clk after 5 ns when not fin else clk;
  takt <= takt + 1 when rising_edge(clk);

  u8  : entity work.dziel_iter generic map (8, false)  port map (clk, rst, st8, a8, b8, bu8, du8, qu8, ru8, zu8);
  s8  : entity work.dziel_iter generic map (8, true)   port map (clk, rst, st8, a8, b8, bs8, ds8, qs8, rs8, zs8);
  u16 : entity work.dziel_iter generic map (16, false) port map (clk, rst, st16, a16, b16, bu16, du16, qu16, ru16, zu16);
  s16 : entity work.dziel_iter generic map (16, true)  port map (clk, rst, st16, a16, b16, bs16, ds16, qs16, rs16, zs16);
  p8  : entity work.dziel_potok generic map (8)  port map (clk, pv8, pa8, pb8, ov8, pq8, pr8);
  p16 : entity work.dziel_potok generic map (16) port map (clk, pv16, pa16, pb16, ov16, pq16, pr16);
  q8  : entity work.pierw_iter generic map (8)  port map (clk, rst, sp8, x16, pbz8, pd8, pp8, prs8);
  q16 : entity work.pierw_iter generic map (16) port map (clk, rst, sp16, x32, pbz16, pd16, pp16, prs16);

  -- dziel_potok: wyniki strumienia
  process (clk)
    variable q, r : integer;
  begin
    if rising_edge(clk) then
      if ov8 = '1' then           -- para nr o8 = (o8 / 256, o8 mod 256), podana w takcie t8 + o8
        oczek(8, false, std_logic_vector(to_unsigned(o8 / 256, 8)), std_logic_vector(to_unsigned(o8 mod 256, 8)), q, r);
        if to_integer(unsigned(pq8)) /= q or to_integer(unsigned(pr8)) /= r or takt - (t8 + o8) /= 8 then
          bl_pot <= bl_pot + 1;
        end if;
        o8 <= o8 + 1;
      end if;
      if ov16 = '1' then
        oczek(16, false, gx(o16), gy(o16), q, r);
        if to_integer(unsigned(pq16)) /= q or to_integer(unsigned(pr16)) /= r then
          bl_pot <= bl_pot + 1;
        end if;
        o16 <= o16 + 1;
      end if;
    end if;
  end process;

  process
    variable l : line;
    variable s1, s2 : positive := 5;
    variable rr : real;
    variable errors, q, r, t0, takty_d, takty_p, j, xv : integer := 0;
    variable xp : unsigned(31 downto 0);
    variable p2, p12 : unsigned(63 downto 0);

    impure function los16 return std_logic_vector is
    begin
      uniform(s1, s2, rr);
      return std_logic_vector(to_unsigned(integer(floor(rr * 65536.0)), 16));
    end function;

    function skrajna16(k : natural) return std_logic_vector is
    begin
      case k mod 8 is
        when 0 => return x"8000";
        when 1 => return x"7FFF";
        when 2 => return x"FFFF";
        when 3 => return x"0001";
        when 4 => return x"0000";
        when 5 => return x"0002";
        when 6 => return x"FFFE";
        when others => return x"1234";
      end case;
    end function;

    procedure sprawdz(nazwa : string; qd, rd : std_logic_vector; z : std_logic; qe, re : integer; ze : boolean) is
    begin
      if to_integer(unsigned(qd)) /= qe or to_integer(unsigned(rd)) /= re or (z = '1') /= ze then
        if errors < 12 then
          write(l, nazwa & ": q=" & integer'image(to_integer(unsigned(qd))) & " r=" & integer'image(to_integer(unsigned(rd)))
                & ", oczekiwano " & integer'image(qe) & " " & integer'image(re));
          writeline(output, l);
        end if;
        errors := errors + 1;
      end if;
    end procedure;

    procedure sprawdz_pierw(x : unsigned; p : std_logic_vector; rs : std_logic_vector) is
      variable pv : unsigned(31 downto 0);
    begin
      pv  := resize(unsigned(p), 32);
      p2  := pv * pv;
      p12 := (pv + 1) * (pv + 1);
      if not (p2 <= resize(x, 64) and resize(x, 64) < p12) or resize(unsigned(rs), 64) /= resize(x, 64) - p2 then
        if errors < 12 then
          write(l, "pierw(" & to_hstring(x) & ") = " & to_hstring(p)); writeline(output, l);
        end if;
        errors := errors + 1;
      end if;
    end procedure;
  begin
    wait for 22 ns;
    rst <= '0';
    -- dziel_iter W = 8: wszystkie pary
    for i in 0 to 65535 loop
      wait until falling_edge(clk);
      a8 <= std_logic_vector(to_unsigned(i / 256, 8));
      b8 <= std_logic_vector(to_unsigned(i mod 256, 8));
      st8 <= '1'; t0 := takt;
      wait until falling_edge(clk);
      st8 <= '0';
      while du8 /= '1' loop wait until falling_edge(clk); end loop;
      if takty_d = 0 then takty_d := takt - t0; end if;
      oczek(8, false, a8, b8, q, r); sprawdz("u8", qu8, ru8, zu8, q, r, unsigned(b8) = 0);
      oczek(8, true, a8, b8, q, r);  sprawdz("s8", qs8, rs8, zs8, q, r, unsigned(b8) = 0);
    end loop;
    -- W = 16
    for i in 0 to 2999 loop
      wait until falling_edge(clk);
      if i < 64 then a16 <= skrajna16(i); b16 <= skrajna16(i / 8);
      else a16 <= los16; b16 <= los16; end if;
      st16 <= '1';
      wait until falling_edge(clk);
      st16 <= '0';
      while du16 /= '1' loop wait until falling_edge(clk); end loop;
      oczek(16, false, a16, b16, q, r); sprawdz("u16", qu16, ru16, zu16, q, r, unsigned(b16) = 0);
      oczek(16, true, a16, b16, q, r);  sprawdz("s16", qs16, rs16, zs16, q, r, unsigned(b16) = 0);
    end loop;

    -- dziel_potok: strumień bez przerw
    wait until falling_edge(clk);
    t8 <= takt;
    for i in 0 to 65535 loop
      pa8 <= std_logic_vector(to_unsigned(i / 256, 8));
      pb8 <= std_logic_vector(to_unsigned(i mod 256, 8));
      pv8 <= '1';
      if i < 5000 then
        if i < 64 then pa16 <= skrajna16(i); pb16 <= skrajna16(i / 8);
        else
          pa16 <= los16; pb16 <= los16;
        end if;
        pv16 <= '1';
      else
        pv16 <= '0';
      end if;
      wait for 0 ns;                                     -- zapis historii po ustaleniu wejść
      if i < 5000 then gx(i) <= pa16; gy(i) <= pb16; end if;
      wait until falling_edge(clk);
    end loop;
    pv8 <= '0'; pv16 <= '0';
    for k in 1 to 20 loop wait until falling_edge(clk); end loop;
    if o8 /= 65536 or o16 /= 5000 or bl_pot /= 0 then
      write(l, "dziel_potok: wynikow " & integer'image(o8) & " / " & integer'image(o16) & ", bledow "
            & integer'image(bl_pot));
      writeline(output, l);
      errors := errors + 1;
    end if;

    -- pierw_iter
    for i in 0 to 65535 loop
      wait until falling_edge(clk);
      x16 <= std_logic_vector(to_unsigned(i, 16));
      sp8 <= '1'; t0 := takt;
      wait until falling_edge(clk);
      sp8 <= '0';
      while pd8 /= '1' loop wait until falling_edge(clk); end loop;
      if takty_p = 0 then takty_p := takt - t0; end if;
      sprawdz_pierw(unsigned(x16), pp8, prs8);
    end loop;
    for i in 0 to 2999 loop
      wait until falling_edge(clk);
      if i < 16 then
        xp := resize(to_unsigned(i * 4099, 16) * to_unsigned(i * 4099, 16), 32);
      elsif i < 32 then
        xp := x"FFFFFFFF" - to_unsigned(i, 32);
      else
        xp := unsigned(los16) & unsigned(los16);
        if i mod 7 = 0 then
          j  := to_integer(unsigned(los16));
          xp := to_unsigned(j, 16) * to_unsigned(j, 16) - (i mod 2);
        end if;
      end if;
      x32 <= std_logic_vector(xp);
      sp16 <= '1';
      wait until falling_edge(clk);
      sp16 <= '0';
      while pd16 /= '1' loop wait until falling_edge(clk); end loop;
      sprawdz_pierw(unsigned(x32), pp16, prs16);
    end loop;

    write(l, "takty na wynik: dziel_iter W=8 " & integer'image(takty_d) & ", pierw_iter W=8 " & integer'image(takty_p));
    writeline(output, l);
    if takty_d /= 10 or takty_p /= 10 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
