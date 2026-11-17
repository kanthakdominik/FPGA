-- Testbench sync_pulse i sync_bit: dwa kierunki - szybki 100 MHz -> wolny 36,6 MHz i odwrotnie.
-- Impulsy podawane losowo, gdy busy = '0'. Sprawdzane: liczba impulsów odebranych = wysłanych,
-- impuls docelowy trwa 1 takt, poziom przechodzi przez sync_bit w 3 taktach docelowych.
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_sync_pulse is
end entity tb_sync_pulse;

architecture sim of tb_sync_pulse is
  signal clk_f, clk_s : std_logic := '0';
  signal fin          : boolean   := false;
  signal rst          : std_logic := '1';
  signal stop         : boolean   := false;
  signal p1, p2       : std_logic := '0';
  signal b1, q1, b2, q2 : std_logic;
  signal lvl          : std_logic_vector(0 downto 0) := "0";
  signal lvl_s        : std_logic_vector(0 downto 0);
  signal wys1, odb1, wys2, odb2 : natural := 0;
  signal errs_f, errs_s, errs_l : natural := 0;            -- osobny sygnał na proces (jeden sterownik)
begin
  clk_f <= not clk_f after 5 ns when not fin;
  clk_s <= not clk_s after 13.65 ns when not fin;

  u1 : entity work.sync_pulse
    port map (clk_src => clk_f, rst_src => rst, src_pulse => p1, busy => b1,
              clk_dst => clk_s, rst_dst => rst, dst_pulse => q1);
  u2 : entity work.sync_pulse
    port map (clk_src => clk_s, rst_src => rst, src_pulse => p2, busy => b2,
              clk_dst => clk_f, rst_dst => rst, dst_pulse => q2);
  u3 : entity work.sync_bit
    generic map (STAGES => 2, W => 1)
    port map (clk => clk_s, d => lvl, q => lvl_s);

  -- nadawcy i liczniki w domenie szybkiej
  process (clk_f)
    variable s1, s2 : positive := 3;
    variable x      : real;
    variable q2_d   : std_logic := '0';
  begin
    if falling_edge(clk_f) then
      uniform(s1, s2, x);
      if rst = '0' and not stop and b1 = '0' and x < 0.25 then p1 <= '1'; else p1 <= '0'; end if;
    end if;
    if rising_edge(clk_f) and rst = '0' then
      if p1 = '1' and b1 = '0' then wys1 <= wys1 + 1; end if;
      if q2 = '1' then odb2 <= odb2 + 1; end if;
      if q2 = '1' and q2_d = '1' then errs_f <= errs_f + 1; end if;
      q2_d := q2;
    end if;
  end process;

  -- nadawcy i liczniki w domenie wolnej
  process (clk_s)
    variable s1, s2 : positive := 4;
    variable x      : real;
    variable q1_d   : std_logic := '0';
  begin
    if falling_edge(clk_s) then
      uniform(s1, s2, x);
      if rst = '0' and not stop and b2 = '0' and x < 0.5 then p2 <= '1'; else p2 <= '0'; end if;
    end if;
    if rising_edge(clk_s) and rst = '0' then
      if p2 = '1' and b2 = '0' then wys2 <= wys2 + 1; end if;
      if q1 = '1' then odb1 <= odb1 + 1; end if;
      if q1 = '1' and q1_d = '1' then errs_s <= errs_s + 1; end if;
      q1_d := q1;
    end if;
  end process;

  -- poziom
  process
    variable s1, s2 : positive := 8;
    variable x      : real;
  begin
    wait until rst = '0';
    for k in 1 to 40 loop
      uniform(s1, s2, x);
      for i in 1 to 5 + integer(floor(x * 16.0)) loop
        wait until falling_edge(clk_f);
      end loop;
      lvl(0) <= not lvl(0);
      for i in 1 to 3 loop
        wait until rising_edge(clk_s);
      end loop;
      wait for 1 ns;
      if lvl_s /= lvl then
        report "poziom nie dotarl w 3 taktach" severity warning;
        errs_l <= errs_l + 1;
      end if;
    end loop;
    wait;
  end process;

  process
    variable l      : line;
    variable errors : natural;
  begin
    wait for 100 ns;
    rst <= '0';
    wait for 40000 ns;
    stop <= true;                              -- koniec: brak nowych impulsów, czas na dotarcie ostatnich
    wait for 500 ns;
    errors := errs_f + errs_s + errs_l;
    write(l, "szybki->wolny: wyslano " & integer'image(wys1) & ", odebrano " & integer'image(odb1) &
             "; wolny->szybki: wyslano " & integer'image(wys2) & ", odebrano " & integer'image(odb2));
    writeline(output, l);
    if wys1 /= odb1 or wys2 /= odb2 then errors := errors + 1; end if;
    if wys1 < 100 or wys2 < 100 then errors := errors + 1; end if;
    if errors = 0 then
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
