-- Testbench zadania 12 (VHDL): odpowiedź impulsowa, stała 1000 (wyjście 256 000), 2000 losowych próbek
-- z losowym en; model splotu z 8 ostatnimi próbkami.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_fir_transposed is
end entity;

architecture sim of tb_fir_transposed is
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst : std_logic := '1';
  signal en  : std_logic := '0';
  signal x   : signed(11 downto 0) := (others => '0');
  signal y   : signed(23 downto 0);

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.fir_transposed port map (clk => clk, rst => rst, en => en, x => x, y => y);

  process
    type ints_t is array (0 to 7) of integer;
    constant H                : ints_t := (2, -10, 40, 96, 96, 40, -10, 2);
    variable hist             : ints_t := (others => 0);
    variable s1, s2           : positive := 6;
    variable r                : real;
    variable exp_y, y_max     : integer := 0;
    variable errors, n        : natural := 0;
    variable v_en             : std_logic;
    variable v_x              : integer;

    -- jedna próbka: wejście na zboczu opadającym, model po zboczu, sprawdzenie na następnym zboczu opadającym
    procedure probka(e : std_logic; xv : integer) is
    begin
      en <= e;
      x  <= to_signed(xv, 12);
      wait until rising_edge(clk);
      if e = '1' then
        for k in 7 downto 1 loop hist(k) := hist(k - 1); end loop;
        hist(0) := xv;
        exp_y := 0;
        for k in 0 to 7 loop exp_y := exp_y + H(k) * hist(k); end loop;
        n := n + 1;
      end if;
      wait until falling_edge(clk);
      if to_integer(y) /= exp_y then
        say("y=" & integer'image(to_integer(y)) & ", oczekiwano " & integer'image(exp_y)); errors := errors + 1;
      end if;
      if abs exp_y > y_max then y_max := abs exp_y; end if;
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    probka('1', 1);
    for i in 1 to 7 loop
      if to_integer(y) /= H(i - 1) then say("impuls: zly wspolczynnik"); errors := errors + 1; end if;
      probka('1', 0);
    end loop;
    for i in 1 to 10 loop probka('1', 1000); end loop;
    if to_integer(y) /= 256000 then say("stala: y=" & integer'image(to_integer(y))); errors := errors + 1; end if;
    for i in 0 to 1999 loop
      uniform(s1, s2, r);
      if r < 0.75 then v_en := '1'; else v_en := '0'; end if;
      uniform(s1, s2, r);
      if i mod 200 < 20 then
        if i mod 2 = 1 then v_x := 2047; else v_x := -2048; end if;
      else
        v_x := integer(floor(r * 4096.0)) - 2048;
      end if;
      probka(v_en, v_x);
    end loop;
    say("probek " & integer'image(n) & ", najwiekszy |y| = " & integer'image(y_max) & " (zakres 24 bitow: 8388607)");
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
