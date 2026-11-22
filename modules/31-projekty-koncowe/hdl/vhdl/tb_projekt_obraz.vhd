-- Testbench projektu 5 (31.05), VHDL: te same ramki, model sceny i sprawdzenia co tb_projekt_obraz.v.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_projekt_obraz is
end entity tb_projekt_obraz;

architecture sim of tb_projekt_obraz is
  constant W : positive := 64;
  constant H : positive := 32;
  constant PROG : natural := 20;
  signal clk  : std_logic := '0';
  signal fin  : boolean := false;
  signal rst  : std_logic := '1';
  signal tryb : unsigned(2 downto 0) := "000";
  signal de, hs, vs : std_logic;
  signal rgb  : std_logic_vector(23 downto 0);
  signal suma_y : unsigned(31 downto 0);
  type obraz_t is array (0 to W * H - 1) of std_logic_vector(23 downto 0);
  signal obraz : obraz_t;
  signal zapis, gotowa : boolean := false;
  signal n_ramek, n_pikseli : natural := 0;

  procedure pisz(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;

  function obszar(x, y : integer) return integer is
  begin
    if x < 8 and y >= H / 2 and y < H / 2 + 8 then return 8;
    elsif y < H / 2 then return (x * 8) / W;
    else return 9;
    end if;
  end function;
  function kolor(x, y : integer) return std_logic_vector is
    variable k : integer;
    variable r, g, b, gr : natural;
  begin
    k := obszar(x, y);
    gr := (x * 256) / W;
    if k = 8 then return x"FFFFFF";
    elsif k = 9 then
      return std_logic_vector(to_unsigned(gr, 8)) & std_logic_vector(to_unsigned(gr, 8))
             & std_logic_vector(to_unsigned(gr, 8));
    else
      if k = 0 or k = 1 or k = 4 or k = 5 then r := 220; else r := 30; end if;
      if k <= 3 then g := 220; else g := 30; end if;
      if k = 0 or k = 2 or k = 4 or k = 6 then b := 220; else b := 30; end if;
      return std_logic_vector(to_unsigned(r, 8)) & std_logic_vector(to_unsigned(g, 8))
             & std_logic_vector(to_unsigned(b, 8));
    end if;
  end function;
  function jasn(c : std_logic_vector(23 downto 0)) return natural is
  begin
    return ((77 * to_integer(unsigned(c(23 downto 16))) + 150 * to_integer(unsigned(c(15 downto 8)))
             + 29 * to_integer(unsigned(c(7 downto 0))) + 128) / 256) mod 256;
  end function;
  function jednolite(x, y, r : integer) return boolean is
    variable k0 : integer;
  begin
    if not (x >= r and x < W - r and y >= r and y < H - r) then return false; end if;
    k0 := obszar(x, y);
    for i in -r to r loop
      for j in -r to r loop
        if obszar(x + i, y + j) /= k0 then return false; end if;
      end loop;
    end loop;
    return true;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;
  dut : entity work.projekt_obraz
    generic map (H_AKT => W, H_FP => 2, H_SYNC => 4, H_BP => 2, V_AKT => H, V_FP => 1, V_SYNC => 2, V_BP => 1,
                 PROG => PROG)
    port map (clk => clk, rst => rst, tryb => tryb, ruch => '0', de => de, hs => hs, vs => vs, rgb => rgb,
              suma_y => suma_y);

  zapis_ramki : process (clk)
    variable vs_p : std_logic := '1';
    variable de_p : std_logic := '0';
    variable w_ramce : boolean := false;
    variable px, ln, np : natural := 0;
  begin
    if rising_edge(clk) then
      if vs_p = '1' and vs = '0' then
        n_ramek <= n_ramek + 1;
        ln := 0;
        if w_ramce then w_ramce := false; gotowa <= true; n_pikseli <= np;
        elsif zapis and not gotowa then w_ramce := true; np := 0;
        end if;
      elsif de_p = '1' and de = '0' then
        ln := ln + 1;
      end if;
      if not zapis then gotowa <= false; end if;
      if w_ramce and de = '1' then
        if px < W and ln < H then obraz(ln * W + px) <= rgb; end if;
        np := np + 1;
      end if;
      if de = '1' then px := px + 1; else px := 0; end if;
      vs_p := vs;
      de_p := de;
    end if;
  end process;

  process
    variable bledy, spr, zle, n0 : integer := 0;
    variable v : natural;
    variable suma_tb : natural;
    variable p : std_logic_vector(23 downto 0);

    procedure ramka_w_trybie(t : natural) is
    begin
      tryb <= to_unsigned(t, 3);
      n0 := n_ramek;
      wait until n_ramek >= n0 + 2;
      zapis <= true;
      wait until gotowa;
      zapis <= false;
      wait until rising_edge(clk);
      if n_pikseli /= W * H then pisz("FAIL: " & integer'image(n_pikseli) & " pikseli w ramce"); bledy := bledy + 1; end if;
    end procedure;
  begin
    for i in 1 to 5 loop wait until rising_edge(clk); end loop;
    rst <= '0';
    ramka_w_trybie(0);
    spr := 0; zle := 0;
    for y in 0 to H - 1 loop
      for x in 0 to W - 1 loop
        if jednolite(x, y, 1) then
          spr := spr + 1;
          if obraz(y * W + x) /= kolor(x, y) then zle := zle + 1; end if;
        end if;
      end loop;
    end loop;
    pisz("tryb 0 (kolor): pikseli z jednolitym oknem 3x3 " & integer'image(spr) & ", niezgodnych " & integer'image(zle));
    if zle /= 0 or spr < 900 then bledy := bledy + 1; end if;

    ramka_w_trybie(1);
    spr := 0; zle := 0; suma_tb := 0;
    for y in 0 to H - 1 loop
      for x in 0 to W - 1 loop
        p := obraz(y * W + x);
        suma_tb := suma_tb + to_integer(unsigned(p(7 downto 0)));
        if p(23 downto 16) /= p(7 downto 0) then zle := zle + 1; end if;
        if jednolite(x, y, 1) then
          spr := spr + 1;
          if to_integer(unsigned(p(7 downto 0))) /= jasn(kolor(x, y)) then zle := zle + 1; end if;
        end if;
      end loop;
    end loop;
    pisz("tryb 1 (szarosc): sprawdzonych " & integer'image(spr) & ", niezgodnych " & integer'image(zle)
         & "; suma Y ramki " & integer'image(to_integer(suma_y)) & " (z obrazu " & integer'image(suma_tb) & ")");
    if zle /= 0 or to_integer(suma_y) /= suma_tb then bledy := bledy + 1; end if;

    for k in 2 to 4 loop
      ramka_w_trybie(k);
      spr := 0; zle := 0;
      for y in 0 to H - 1 loop
        for x in 0 to W - 1 loop
          if jednolite(x, y, 2) then
            spr := spr + 1;
            if k = 2 then v := jasn(kolor(x, y));
            elsif k = 3 then
              if obszar(x, y) = 9 then v := 32; else v := 0; end if;
            else
              if obszar(x, y) = 9 and 32 >= PROG then v := 255; else v := 0; end if;
            end if;
            p := obraz(y * W + x);
            if p /= std_logic_vector(to_unsigned(v, 8)) & std_logic_vector(to_unsigned(v, 8))
                    & std_logic_vector(to_unsigned(v, 8)) then
              zle := zle + 1;
            end if;
          end if;
        end loop;
      end loop;
      pisz("tryb " & integer'image(k) & ": sprawdzonych pikseli " & integer'image(spr) & ", niezgodnych "
           & integer'image(zle));
      if zle /= 0 or spr < 600 then bledy := bledy + 1; end if;
    end loop;
    if bledy = 0 then pisz("PASS"); else pisz("FAIL: " & integer'image(bledy) & " bledow"); end if;
    fin <= true;
    wait;
  end process;
end architecture sim;
