-- Testbench 24.01: takt_wideo w trzech trybach — 640×480 przy 60 Hz (impulsy ujemne), 1280×720 przy 60 Hz
-- (impulsy dodatnie) i mały tryb próbny. spr_takt mierzy: piksele aktywne w linii, szerokości i położenie
-- impulsów, okres linii i ramki, linie aktywne, zgodność x/y z pozycją i nowa_ramka na pikselu (0, 0).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity spr_takt is
  generic (
    NAZWA  : string := "tryb";
    H_AKT  : positive := 640; H_FP : positive := 16; H_SYNC : positive := 96; H_BP : positive := 48;
    V_AKT  : positive := 480; V_FP : positive := 10; V_SYNC : positive := 2;  V_BP : positive := 33;
    H_POL  : std_logic := '0'; V_POL : std_logic := '0';
    RAMEK  : positive := 2;
    OKRES  : time := 39722 ps
  );
  port (
    koniec : out boolean := false;
    bledy  : out natural := 0
  );
end entity spr_takt;

architecture sim of spr_takt is
  constant H_TOT : natural := H_AKT + H_FP + H_SYNC + H_BP;
  constant V_TOT : natural := V_AKT + V_FP + V_SYNC + V_BP;
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal hs, vs, de, nowa_ramka : std_logic;
  signal x, y : unsigned(11 downto 0);
  signal ramka : integer := -1;
  signal bl : natural := 0;
begin
  clk <= not clk after OKRES / 2 when ramka < RAMEK else clk;
  rst <= '0' after 3 * OKRES;
  bledy <= bl;

  dut : entity work.takt_wideo
    generic map (H_AKT => H_AKT, H_FP => H_FP, H_SYNC => H_SYNC, H_BP => H_BP, V_AKT => V_AKT, V_FP => V_FP,
                 V_SYNC => V_SYNC, V_BP => V_BP, H_POL => H_POL, V_POL => V_POL)
    port map (clk => clk, rst => rst, hs => hs, vs => vs, de => de, x => x, y => y, nowa_ramka => nowa_ramka);

  process (clk)
    variable hc, vc : integer := 0;
    variable de_w, hs_w, hs_st, l_akt, vs_l, vs_st, n_bl, t, pocz, okres_r, bl_xy, bl_de : integer := 0;
    variable vs_akt, hs_a, vs_a : boolean := false;
    variable fr : integer := -1;
    variable l : line;
    procedure blad(co : string; jest, ma : integer) is
    begin
      if n_bl < 10 then
        write(l, "  " & NAZWA & ": " & co & " = " & integer'image(jest) & ", oczekiwano " & integer'image(ma)
              & " (linia " & integer'image(vc) & ", ramka " & integer'image(fr) & ")");
        writeline(output, l);
      end if;
      n_bl := n_bl + 1;
    end procedure;
  begin
    if rising_edge(clk) and rst = '0' then
      hs_a := hs = H_POL;
      vs_a := vs = V_POL;
      if nowa_ramka = '1' then
        if fr >= 0 then
          if hc /= H_TOT - 1 or vc /= V_TOT - 1 then blad("koniec ramki przed nowa_ramka", hc, H_TOT - 1); end if;
          okres_r := t - pocz;
          if okres_r /= H_TOT * V_TOT then blad("okres ramki w taktach", okres_r, H_TOT * V_TOT); end if;
          if l_akt /= V_AKT then blad("linie aktywne", l_akt, V_AKT); end if;
          if vs_l /= V_SYNC then blad("szerokosc VS w liniach", vs_l, V_SYNC); end if;
          if vs_st /= V_AKT + V_FP then blad("poczatek VS (linia)", vs_st, V_AKT + V_FP); end if;
        end if;
        pocz := t; fr := fr + 1; hc := 0; vc := 0; l_akt := 0; vs_l := 0; vs_st := -1;
        if de /= '1' or x /= 0 or y /= 0 then blad("nowa_ramka poza pikselem (0,0)", to_integer(x), 0); end if;
      elsif fr >= 0 then
        if hc = H_TOT - 1 then hc := 0; vc := vc + 1; else hc := hc + 1; end if;
      end if;
      if fr >= 0 then
        if (de = '1') /= (hc < H_AKT and vc < V_AKT) then bl_de := bl_de + 1; end if;
        if to_integer(x) /= hc or to_integer(y) /= vc then bl_xy := bl_xy + 1; end if;
        if hc = 0 then
          de_w := 0; hs_w := 0; hs_st := -1;
          if vs_a and not vs_akt then vs_st := vc; end if;
          if vs_a then vs_l := vs_l + 1; end if;
          vs_akt := vs_a;
          if de = '1' then l_akt := l_akt + 1; end if;
        end if;
        if de = '1' then de_w := de_w + 1; end if;
        if hs_a then
          if hs_st < 0 then hs_st := hc; end if;
          hs_w := hs_w + 1;
        end if;
        if vs_a and hc /= 0 and not vs_akt then blad("VS zmienia sie w srodku linii", hc, 0); end if;
        if hc = H_TOT - 1 then
          if vc < V_AKT and de_w /= H_AKT then blad("piksele aktywne w linii", de_w, H_AKT); end if;
          if vc >= V_AKT and de_w /= 0 then blad("piksele aktywne w wygaszaniu", de_w, 0); end if;
          if hs_w /= H_SYNC then blad("szerokosc HS", hs_w, H_SYNC); end if;
          if hs_st /= H_AKT + H_FP then blad("poczatek HS", hs_st, H_AKT + H_FP); end if;
        end if;
      end if;
      t := t + 1;
      if fr = RAMEK then
        if bl_xy /= 0 then blad("niezgodne x/y", bl_xy, 0); end if;
        if bl_de /= 0 then blad("de poza obszarem aktywnym", bl_de, 0); end if;
        write(l, "  " & NAZWA & ": linia " & integer'image(H_TOT) & " taktow (HS " & integer'image(H_SYNC) & " od "
              & integer'image(H_AKT + H_FP) & "), ramka " & integer'image(V_TOT) & " linii = "
              & integer'image(H_TOT * V_TOT) & " taktow, " & integer'image(RAMEK) & " ramek: "
              & integer'image(n_bl) & " bledow");
        writeline(output, l);
        write(l, "    odswiezanie " & real'image(1.0e12 / (real(OKRES / 1 ps) * real(H_TOT * V_TOT))) & " Hz");
        writeline(output, l);
        koniec <= true;
      end if;
      ramka <= fr;
      bl <= n_bl;
    end if;
  end process;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_takt is
end entity tb_takt;

architecture sim of tb_takt is
  signal k1, k2, k3 : boolean;
  signal b1, b2, b3 : natural;
begin
  m640 : entity work.spr_takt
    generic map (NAZWA => "640x480", RAMEK => 2, OKRES => 39722 ps)
    port map (koniec => k1, bledy => b1);
  m720 : entity work.spr_takt
    generic map (NAZWA => "1280x720", H_AKT => 1280, H_FP => 110, H_SYNC => 40, H_BP => 220,
                 V_AKT => 720, V_FP => 5, V_SYNC => 5, V_BP => 20, H_POL => '1', V_POL => '1',
                 RAMEK => 1, OKRES => 13468 ps)
    port map (koniec => k2, bledy => b2);
  mmaly : entity work.spr_takt
    generic map (NAZWA => "maly", H_AKT => 8, H_FP => 1, H_SYNC => 2, H_BP => 1,
                 V_AKT => 4, V_FP => 1, V_SYNC => 1, V_BP => 1, H_POL => '1', V_POL => '0',
                 RAMEK => 5, OKRES => 10 ns)
    port map (koniec => k3, bledy => b3);

  process
    variable l : line;
  begin
    wait until k1 and k2 and k3;
    wait for 100 ns;
    if b1 + b2 + b3 = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(b1 + b2 + b3) & " bledow"); end if;
    writeline(output, l);
    std.env.finish;
    wait;
  end process;
end architecture sim;
