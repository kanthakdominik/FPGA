-- Testbench 24.02: tmds_kod. 300 000 symboli w „liniach” (64 piksele aktywne, 16 wygaszania ze znakami
-- sterującymi), dane losowe i wzorce 00, FF, 55, AA, 0F. Sprawdza dekodowanie, znaki sterujące, nierównowagę
-- w linii (≤ 8) i liczbę zmian (dane ≤ 5, znaki sterujące ≥ 7).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_tmds is
end entity tb_tmds;

architecture sim of tb_tmds is
  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
  signal d   : std_logic_vector(7 downto 0) := x"00";
  signal c   : std_logic_vector(1 downto 0) := "00";
  signal de  : std_logic := '0';
  signal q   : std_logic_vector(9 downto 0);
  signal fin : boolean := false;

  function dekod(s : std_logic_vector(9 downto 0)) return std_logic_vector is
    variable v, r : std_logic_vector(7 downto 0);
  begin
    if s(9) = '1' then v := not s(7 downto 0); else v := s(7 downto 0); end if;
    r(0) := v(0);
    for i in 1 to 7 loop
      if s(8) = '1' then r(i) := v(i) xor v(i - 1); else r(i) := not (v(i) xor v(i - 1)); end if;
    end loop;
    return r;
  end function;
  function zmiany(s : std_logic_vector(9 downto 0)) return natural is
    variable n : natural := 0;
  begin
    for i in 0 to 8 loop
      if s(i) /= s(i + 1) then n := n + 1; end if;
    end loop;
    return n;
  end function;
  function jedynki(s : std_logic_vector(9 downto 0)) return natural is
    variable n : natural := 0;
  begin
    for i in 0 to 9 loop
      if s(i) = '1' then n := n + 1; end if;
    end loop;
    return n;
  end function;
  function steruj(cc : std_logic_vector(1 downto 0)) return std_logic_vector is
  begin
    case cc is
      when "00"   => return "1101010100";
      when "01"   => return "0010101011";
      when "10"   => return "0101010100";
      when others => return "1010101011";
    end case;
  end function;
begin
  clk <= not clk after 5 ns when not fin else clk;

  dut : entity work.tmds_kod port map (clk => clk, rst => rst, d => d, c => c, de => de, q => q);

  process
    type hd_t is array (0 to 3) of std_logic_vector(7 downto 0);
    type hc_t is array (0 to 3) of std_logic_vector(1 downto 0);
    type hb_t is array (0 to 3) of std_logic;
    type kody_t is array (0 to 1023) of boolean;
    variable h_d : hd_t := (others => x"00");
    variable h_c : hc_t := (others => "00");
    variable h_de : hb_t := (others => '0');
    variable kody : kody_t := (others => false);
    variable s1, s2 : positive := 24;
    variable r : real;
    variable w, z, nier, max_nier, max_zm, min_zm, n_dane, n_ster, bl_dek, bl_ster, rozne, errors : integer := 0;
    variable dd : std_logic_vector(7 downto 0);
    variable cc : std_logic_vector(1 downto 0);
    variable l : line;
  begin
    min_zm := 99;
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for n in 0 to 300001 loop
      wait until falling_edge(clk);
      if n >= 2 then
        w := (n - 2) mod 4;
        if h_de(w) = '1' then
          n_dane := n_dane + 1;
          if dekod(q) /= h_d(w) then bl_dek := bl_dek + 1; end if;
          nier := nier + 2 * jedynki(q) - 10;
          if abs nier > max_nier then max_nier := abs nier; end if;
          z := zmiany(q);
          if z > max_zm then max_zm := z; end if;
          if not kody(to_integer(unsigned(q))) then kody(to_integer(unsigned(q))) := true; rozne := rozne + 1; end if;
        else
          n_ster := n_ster + 1;
          nier := 0;
          if q /= steruj(h_c(w)) then bl_ster := bl_ster + 1; end if;
          z := zmiany(q);
          if z < min_zm then min_zm := z; end if;
        end if;
      end if;
      if n mod 80 < 64 then de <= '1'; else de <= '0'; end if;
      if (n / 80) mod 7 = 3 then
        case n mod 5 is
          when 0 => dd := x"00";
          when 1 => dd := x"FF";
          when 2 => dd := x"55";
          when 3 => dd := x"AA";
          when others => dd := x"0F";
        end case;
      else
        uniform(s1, s2, r);
        dd := std_logic_vector(to_unsigned(integer(floor(r * 256.0)) mod 256, 8));
      end if;
      d <= dd;
      uniform(s1, s2, r);
      cc := std_logic_vector(to_unsigned(integer(floor(r * 4.0)) mod 4, 2));
      c <= cc;
      h_d(n mod 4) := dd;
      h_c(n mod 4) := cc;
      if n mod 80 < 64 then h_de(n mod 4) := '1'; else h_de(n mod 4) := '0'; end if;
    end loop;
    write(l, "symboli danych " & integer'image(n_dane) & ", sterujacych " & integer'image(n_ster)
          & "; bledow dekodowania " & integer'image(bl_dek) & ", zlych znakow sterujacych " & integer'image(bl_ster));
    writeline(output, l);
    write(l, "roznych slow kodowych danych: " & integer'image(rozne) & "; max |jedynki - zera| w linii: "
          & integer'image(max_nier));
    writeline(output, l);
    write(l, "zmian w symbolu: dane maks. " & integer'image(max_zm) & ", znaki sterujace min. " & integer'image(min_zm));
    writeline(output, l);
    if bl_dek /= 0 or bl_ster /= 0 then errors := errors + 1; end if;
    if max_nier > 8 then errors := errors + 1; end if;
    if max_zm > 5 then errors := errors + 1; end if;
    if min_zm < 7 then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
