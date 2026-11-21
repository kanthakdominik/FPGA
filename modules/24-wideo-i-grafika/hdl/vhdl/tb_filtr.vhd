-- Testbench 24.06: takt_wideo + filtr3x3, obraz 24×10 (L = 30, 13 linii na ramkę), 12 ramek, tryb = ramka mod 4,
-- obrazy: gradient, szachownica 0/255, losowe; śmieci w wygaszaniu. Każdy piksel porównany z modelem
-- (splot z uzupełnieniem zerami), de/hs/vs — z wejściowymi opóźnionymi o L + 4 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_filtr is
end entity tb_filtr;

architecture sim of tb_filtr is
  constant W  : positive := 24;
  constant H  : positive := 10;
  constant L  : positive := 30;
  constant OP : positive := L + 4;

  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal fin : boolean := false;
  signal hs, vs, de, nowa_ramka : std_logic;
  signal x, y : unsigned(11 downto 0);
  signal tryb : std_logic_vector(1 downto 0) := "00";
  signal piks : std_logic_vector(7 downto 0);
  signal o_de, o_hs, o_vs : std_logic;
  signal o_piks : std_logic_vector(7 downto 0);

  type obraz_t is array (0 to H - 1, 0 to W - 1) of natural;
  signal img : obraz_t := (others => (others => 0));
  signal tryb_wy, fr : natural := 0;
  signal n_pix, bl_pix, bl_syn, n_nas, n_kraw : natural := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_takt : entity work.takt_wideo
    generic map (H_AKT => W, H_FP => 2, H_SYNC => 2, H_BP => 2, V_AKT => H, V_FP => 1, V_SYNC => 1, V_BP => 1,
                 H_POL => '1', V_POL => '1')
    port map (clk => clk, rst => rst, hs => hs, vs => vs, de => de, x => x, y => y, nowa_ramka => nowa_ramka);

  dut : entity work.filtr3x3
    generic map (L => L, PROG => 128)
    port map (clk => clk, tryb => tryb, de => de, hs => hs, vs => vs, piks => piks,
              o_de => o_de, o_hs => o_hs, o_vs => o_vs, o_piks => o_piks);

  piks <= std_logic_vector(to_unsigned(img(to_integer(y), to_integer(x)), 8))
          when de = '1' and to_integer(y) < H and to_integer(x) < W
          else x"A5" xor std_logic_vector(x(7 downto 0));

  -- kontrola synchronizacji i pikseli
  process (clk)
    type hist_t is array (0 to 63) of std_logic_vector(2 downto 0);
    variable hist : hist_t := (others => "000");
    variable t, ox, oy : natural := 0;
    variable ode_d, ovs_d : std_logic := '0';
    variable e : natural;
    variable ln : line;

    impure function p(xx, yy : integer) return integer is
    begin
      if xx < 0 or xx >= W or yy < 0 or yy >= H then return 0; else return img(yy, xx); end if;
    end function;
    impure function ocz(tt, xx, yy : integer) return natural is
      variable gx, gy, s : integer;
    begin
      gx := p(xx+1, yy-1) + 2 * p(xx+1, yy) + p(xx+1, yy+1) - p(xx-1, yy-1) - 2 * p(xx-1, yy) - p(xx-1, yy+1);
      gy := p(xx-1, yy+1) + 2 * p(xx, yy+1) + p(xx+1, yy+1) - p(xx-1, yy-1) - 2 * p(xx, yy-1) - p(xx+1, yy-1);
      s  := abs gx + abs gy;
      case tt is
        when 0 => return p(xx, yy);
        when 1 => return (p(xx-1, yy-1) + 2 * p(xx, yy-1) + p(xx+1, yy-1) + 2 * p(xx-1, yy) + 4 * p(xx, yy)
                          + 2 * p(xx+1, yy) + p(xx-1, yy+1) + 2 * p(xx, yy+1) + p(xx+1, yy+1) + 8) / 16;
        when 2 => if s > 255 then return 255; else return s; end if;
        when others => if s >= 128 then return 255; else return 0; end if;
      end case;
    end function;
  begin
    if rising_edge(clk) and rst = '0' then
      hist(t mod 64) := de & hs & vs;
      if t >= OP and (o_de & o_hs & o_vs) /= hist((t - OP) mod 64) then bl_syn <= bl_syn + 1; end if;
      t := t + 1;
      if o_de = '1' then
        e := ocz(tryb_wy, ox, oy);
        if to_integer(unsigned(o_piks)) /= e then
          if bl_pix < 5 then
            write(ln, "ramka " & integer'image(fr) & " tryb " & integer'image(tryb_wy) & " (" & integer'image(ox) & ","
                  & integer'image(oy) & "): " & integer'image(to_integer(unsigned(o_piks))) & ", oczekiwano "
                  & integer'image(e));
            writeline(output, ln);
          end if;
          bl_pix <= bl_pix + 1;
        end if;
        if tryb_wy = 2 and o_piks = x"FF" then n_nas <= n_nas + 1; end if;
        if tryb_wy = 3 and o_piks = x"FF" then n_kraw <= n_kraw + 1; end if;
        n_pix <= n_pix + 1;
        ox := ox + 1;
      end if;
      if ode_d = '1' and o_de = '0' then ox := 0; oy := oy + 1; end if;
      if o_vs = '1' and ovs_d = '0' then oy := 0; end if;
      ode_d := o_de; ovs_d := o_vs;
    end if;
  end process;

  process
    variable ln : line;
    variable errors : natural := 0;
    variable s1, s2 : positive := 6;
    variable r : real;
    variable vs_d : std_logic := '0';
    variable nowy : obraz_t;
    variable f : natural := 0;

    procedure generuj(ff : natural) is
    begin
      for j in 0 to H - 1 loop
        for i in 0 to W - 1 loop
          case ff mod 3 is
            when 0 => nowy(j, i) := (i * 10 + j * 7) mod 256;
            when 1 => if ((i / 2) + (j / 2)) mod 2 = 1 then nowy(j, i) := 255; else nowy(j, i) := 0; end if;
            when others =>
              uniform(s1, s2, r);
              nowy(j, i) := integer(floor(r * 256.0)) mod 256;
          end case;
        end loop;
      end loop;
      img <= nowy;
    end procedure;
  begin
    generuj(0);
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    while f < 12 loop
      wait until rising_edge(clk);
      if vs = '1' and vs_d = '0' then
        wait until falling_edge(clk);
        f := f + 1;
        generuj(f);
        tryb <= std_logic_vector(to_unsigned(f mod 4, 2));
        tryb_wy <= f mod 4;
        fr <= f;
        vs_d := '1';
      else
        vs_d := vs;
      end if;
    end loop;
    wait for 1 ns;
    write(ln, "ramek " & integer'image(f) & ", pikseli sprawdzonych " & integer'image(n_pix) & ", bledow pikseli "
          & integer'image(bl_pix) & ", bledow synchronizacji " & integer'image(bl_syn));
    writeline(output, ln);
    write(ln, "Sobel nasycony (255): " & integer'image(n_nas) & " pikseli; krawedzie (prog 128): "
          & integer'image(n_kraw) & " pikseli; opoznienie " & integer'image(OP) & " taktow");
    writeline(output, ln);
    if bl_pix /= 0 or bl_syn /= 0 or n_pix /= 12 * W * H or n_nas = 0 or n_kraw = 0 then errors := errors + 1; end if;
    if errors = 0 then write(ln, string'("PASS"));
    else write(ln, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, ln);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
