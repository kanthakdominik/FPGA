-- Testbench sumator_drzewo: cztery warianty (PIPE/RET = 0/0, 1/0, 2/0, 0/2) na tych samych danych.
-- Sprawdzane: wynik = suma ośmiu wejść, opóźnienie dokładnie 2 + PIPE + RET taktów, wynik w każdym
-- takcie, out_valid tylko dla danych z in_valid = '1'.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_sumator_drzewo is
end entity tb_sumator_drzewo;

architecture sim of tb_sumator_drzewo is
  constant W    : positive := 16;
  constant NCYK : positive := 2000;
  type lat_t is array (0 to 3) of natural;
  constant LAT  : lat_t := (2, 3, 4, 4);
  subtype wynik_t is std_logic_vector(W + 2 downto 0);
  type wyniki_t is array (0 to 3) of wynik_t;
  type exp_s_t is array (0 to NCYK + 16) of wynik_t;
  type exp_v_t is array (0 to NCYK + 16) of std_logic;

  signal clk, rst : std_logic := '1';
  signal in_valid : std_logic := '0';
  signal x        : std_logic_vector(8 * W - 1 downto 0) := (others => '0');
  signal v        : std_logic_vector(0 to 3);
  signal y        : wyniki_t;
  signal exp_s    : exp_s_t;
  signal exp_v    : exp_v_t := (others => '0');
  signal cyk      : natural := 0;
  signal fin      : boolean := false;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u0 : entity work.sumator_drzewo generic map (W => W, PIPE => 0, RET => 0)
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => v(0), y => y(0));
  u1 : entity work.sumator_drzewo generic map (W => W, PIPE => 1, RET => 0)
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => v(1), y => y(1));
  u2 : entity work.sumator_drzewo generic map (W => W, PIPE => 2, RET => 0)
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => v(2), y => y(2));
  u3 : entity work.sumator_drzewo generic map (W => W, PIPE => 0, RET => 2)
    port map (clk => clk, rst => rst, in_valid => in_valid, x => x, out_valid => v(3), y => y(3));

  -- model: suma i ważność danych próbkowanych na zboczu numer cyk
  process (clk)
    variable s : unsigned(W + 2 downto 0);
  begin
    if rising_edge(clk) and cyk <= NCYK + 16 then
      s := (others => '0');
      for i in 0 to 7 loop
        s := s + resize(unsigned(x((i + 1) * W - 1 downto i * W)), W + 3);
      end loop;
      exp_s(cyk) <= std_logic_vector(s);
      exp_v(cyk) <= in_valid and not rst;
      cyk <= cyk + 1;
    end if;
  end process;

  process
    variable s1, s2 : positive := 7;
    variable r      : real;
    variable l      : line;
    variable errors, nwe, n : integer := 0;
    type nv_t is array (0 to 3) of natural;
    variable nv : nv_t := (others => 0);
  begin
    wait for 23 ns;
    rst <= '0';
    for t in 1 to NCYK loop
      wait until falling_edge(clk);
      for j in 0 to 3 loop
        n := cyk - LAT(j);
        if n >= 0 then
          if v(j) /= exp_v(n) then
            write(l, "L=" & integer'image(LAT(j)) & ": out_valid niezgodny w takcie " & integer'image(n));
            writeline(output, l);
            errors := errors + 1;
          end if;
          if v(j) = '1' then
            nv(j) := nv(j) + 1;
            if y(j) /= exp_s(n) then
              write(l, "L=" & integer'image(LAT(j)) & ": zly wynik w takcie " & integer'image(n));
              writeline(output, l);
              errors := errors + 1;
            end if;
          end if;
        end if;
      end loop;
      if in_valid = '1' then
        nwe := nwe + 1;
      end if;
      -- nowe pobudzenia; czasem same jedynki (najdłuższe przeniesienia)
      for i in 0 to 7 loop
        uniform(s1, s2, r);
        if r < 0.125 then
          x((i + 1) * W - 1 downto i * W) <= (others => '1');
        else
          uniform(s1, s2, r);
          x((i + 1) * W - 1 downto i * W) <= std_logic_vector(to_unsigned(integer(floor(r * 65536.0)) mod 65536, W));
        end if;
      end loop;
      uniform(s1, s2, r);
      if r < 0.75 then in_valid <= '1'; else in_valid <= '0'; end if;
    end loop;
    write(l, "wyniki: L2 " & integer'image(nv(0)) & ", L3 " & integer'image(nv(1)) & ", L4 " & integer'image(nv(2))
          & ", L4 (RET) " & integer'image(nv(3)) & " z " & integer'image(nwe) & " danych");
    writeline(output, l);
    if errors = 0 and nv(0) > NCYK / 2 and nv(3) > NCYK / 2 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
