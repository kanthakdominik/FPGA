-- Testbench projektu 2 (31.02), VHDL: te same pobudzenia, analiza ramek i model co tb_oscyloskop.v.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_oscyloskop is
end entity tb_oscyloskop;

architecture sim of tb_oscyloskop is
  constant AW : positive := 7;
  constant N  : positive := 2 ** AW;
  constant PRZED : positive := 16;
  constant X0 : positive := 8;
  constant Y0 : positive := 8;
  constant POZIOM : natural := 2048;
  constant C_SIATKA : std_logic_vector(23 downto 0) := x"404040";
  constant C_RAMKA  : std_logic_vector(23 downto 0) := x"808080";
  constant C_POZIOM : std_logic_vector(23 downto 0) := x"FF8000";
  constant C_WYZW   : std_logic_vector(23 downto 0) := x"0060FF";
  constant C_SLAD   : std_logic_vector(23 downto 0) := x"00FF00";
  signal clk_a, clk_v : std_logic := '0';
  signal fin    : boolean := false;
  signal rst    : std_logic := '1';
  signal we     : std_logic := '0';
  signal probka : std_logic_vector(11 downto 0) := (others => '0');
  signal stala  : boolean := false;
  signal wyzwolony, hs, vs, de : std_logic;
  signal rgb    : std_logic_vector(23 downto 0);
  signal nr_zrzutu : unsigned(15 downto 0);

  type tab_t is array (0 to N - 1) of integer;
  signal smin, smax, scnt : tab_t;
  signal l_poz, l_wyzw, l_siatka, l_ramka, l_inne, l_slad_poza : integer := 0;
  signal analiza, gotowa : boolean := false;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;

  function tri(n : integer) return integer is
    variable k : integer;
  begin
    k := ((n mod 200) + 200) mod 200;
    if k < 100 then return k * 40; else return (200 - k) * 40; end if;
  end function;
begin
  clk_a <= not clk_a after 5 ns when not fin else clk_a;
  clk_v <= not clk_v after 4 ns when not fin else clk_v;

  dut : entity work.oscyloskop
    generic map (AW => AW, PRZED => PRZED, AUTO => 512, X0 => X0, Y0 => Y0, H_AKT => X0 + N + 8, H_FP => 2,
                 H_SYNC => 4, H_BP => 2, V_AKT => Y0 + 256 + 8, V_FP => 1, V_SYNC => 2, V_BP => 1)
    port map (clk_a => clk_a, rst_a => rst, we => we, probka => probka, poziom => std_logic_vector(to_unsigned(POZIOM, 12)),
              dziel => to_unsigned(1, 8), tryb_auto => '1', wyzwolony => wyzwolony, clk_v => clk_v, rst_v => rst,
              rgb => rgb, hs => hs, vs => vs, de => de, nr_zrzutu => nr_zrzutu);

  zrodlo : process (clk_a)
    variable nr_pr : integer := 0;
    variable faza : std_logic := '0';
  begin
    if rising_edge(clk_a) then
      faza := not faza;
      we <= faza;
      if faza = '1' then
        if stala then probka <= std_logic_vector(to_unsigned(1000, 12));
        else probka <= std_logic_vector(to_unsigned(tri(nr_pr), 12)); end if;
        nr_pr := nr_pr + 1;
      end if;
    end if;
  end process;

  analizator : process (clk_v)
    variable de_d : std_logic := '0';
    variable vs_d : std_logic := '1';
    variable w_ramce : boolean := false;
    variable px, ln, kol, wier : integer := 0;
    variable vmin, vmax, vcnt : tab_t;
    variable a_poz, a_wyzw, a_siatka, a_ramka, a_inne, a_poza : integer := 0;
  begin
    if rising_edge(clk_v) then
      if vs_d = '1' and vs = '0' then
        ln := 0;
        if w_ramce then
          w_ramce := false;
          smin <= vmin; smax <= vmax; scnt <= vcnt;
          l_poz <= a_poz; l_wyzw <= a_wyzw; l_siatka <= a_siatka; l_ramka <= a_ramka; l_inne <= a_inne;
          l_slad_poza <= a_poza;
          gotowa <= true;
        elsif analiza and not gotowa then
          w_ramce := true;
          vmin := (others => 999); vmax := (others => -1); vcnt := (others => 0);
          a_poz := 0; a_wyzw := 0; a_siatka := 0; a_ramka := 0; a_inne := 0; a_poza := 0;
        end if;
      elsif de_d = '1' and de = '0' then
        ln := ln + 1;
      end if;
      if not analiza then gotowa <= false; end if;
      if w_ramce and de = '1' then
        if px >= X0 and px < X0 + N and ln >= Y0 and ln < Y0 + 256 then
          kol := px - X0; wier := ln - Y0;
          if rgb = C_SLAD then
            if wier < vmin(kol) then vmin(kol) := wier; end if;
            if wier > vmax(kol) then vmax(kol) := wier; end if;
            vcnt(kol) := vcnt(kol) + 1;
          elsif rgb = C_POZIOM then a_poz := a_poz + 1;
          elsif rgb = C_WYZW then a_wyzw := a_wyzw + 1;
          elsif rgb = C_SIATKA then a_siatka := a_siatka + 1;
          elsif rgb /= x"000000" then a_inne := a_inne + 1;
          end if;
        elsif rgb = C_RAMKA then a_ramka := a_ramka + 1;
        elsif rgb = C_SLAD then a_poza := a_poza + 1;
        elsif rgb /= x"000000" then a_inne := a_inne + 1;
        end if;
      end if;
      if de = '1' then px := px + 1; else px := 0; end if;
      de_d := de;
      vs_d := vs;
    end if;
  end process;

  process
    variable bledy, n0 : integer := 0;

    procedure analizuj_ramke is
    begin
      analiza <= true;
      wait until gotowa;
      analiza <= false;
      wait until rising_edge(clk_v);
    end procedure;

    function wiersz(p : integer) return integer is
    begin
      return 255 - p / 16;
    end function;

    procedure sprawdz(stala_wart : integer; co : string) is
      variable e_min, e_max : tab_t;
      variable a, b, bl_kol, o_poz, o_wyzw, o_siatka, w_poz : integer;
    begin
      w_poz := 255 - POZIOM / 16;
      for i in 0 to N - 1 loop
        if stala_wart >= 0 then
          a := wiersz(stala_wart); b := a;
        else
          a := wiersz(tri(52 - PRZED + i));
          if i = 0 then b := a; else b := wiersz(tri(52 - PRZED + i - 1)); end if;
        end if;
        if a < b then e_min(i) := a; e_max(i) := b; else e_min(i) := b; e_max(i) := a; end if;
      end loop;
      bl_kol := 0; o_poz := 0; o_wyzw := 0; o_siatka := 0;
      for i in 0 to N - 1 loop
        if smin(i) /= e_min(i) or smax(i) /= e_max(i) or scnt(i) /= e_max(i) - e_min(i) + 1 then
          if bl_kol < 3 then
            pisz("  kolumna " & integer'image(i) & ": slad " & integer'image(smin(i)) & ".." & integer'image(smax(i))
                 & ", oczekiwane " & integer'image(e_min(i)) & ".." & integer'image(e_max(i)));
          end if;
          bl_kol := bl_kol + 1;
        end if;
        for r in 0 to 255 loop
          if not (r >= e_min(i) and r <= e_max(i)) then
            if r = w_poz then o_poz := o_poz + 1;
            elsif i = PRZED then o_wyzw := o_wyzw + 1;
            elsif i mod 64 = 0 or r mod 32 = 0 then o_siatka := o_siatka + 1;
            end if;
          end if;
        end loop;
      end loop;
      pisz(co & ": kolumny zgodne " & integer'image(N - bl_kol) & "/" & integer'image(N) & ", poziom "
           & integer'image(l_poz) & "/" & integer'image(o_poz) & ", znacznik " & integer'image(l_wyzw) & "/"
           & integer'image(o_wyzw) & ", siatka " & integer'image(l_siatka) & "/" & integer'image(o_siatka)
           & ", ramka " & integer'image(l_ramka) & "/" & integer'image(2 * N + 4 + 512));
      if bl_kol /= 0 or l_poz /= o_poz or l_wyzw /= o_wyzw or l_siatka /= o_siatka or l_ramka /= 2 * N + 4 + 512
         or l_inne /= 0 or l_slad_poza /= 0 then
        pisz("FAIL: " & co & ": obraz niezgodny z modelem");
        bledy := bledy + 1;
      end if;
    end procedure;
  begin
    for i in 1 to 5 loop wait until rising_edge(clk_a); end loop;
    rst <= '0';
    wait until nr_zrzutu >= 1;
    if wyzwolony /= '1' then pisz("FAIL: zrzut trojkata bez wyzwolenia"); bledy := bledy + 1; end if;
    analizuj_ramke;
    sprawdz(-1, "trojkat");
    stala <= true;
    n0 := to_integer(nr_zrzutu);
    wait until nr_zrzutu >= n0 + 2;
    if wyzwolony = '1' then pisz("FAIL: stala wyzwolila zrzut"); bledy := bledy + 1; end if;
    analizuj_ramke;
    sprawdz(1000, "stala (auto)");
    pisz("wyswietlonych zrzutow: " & integer'image(to_integer(nr_zrzutu)));
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
