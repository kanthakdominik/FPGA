-- Testbench bramkowanie: 400 taktów z losowym en (rejestr taktowany clk). Sprawdzane:
-- cnt_icg = cnt_ce w każdym takcie, cnt_and = cnt_ce + liczba okien en = '1' (dodatkowe zbocze
-- zegara bramkowanego bramką AND na początku każdego okna).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_bramkowanie is
end entity tb_bramkowanie;

architecture sim of tb_bramkowanie is
  signal clk     : std_logic := '0';
  signal fin     : boolean   := false;
  signal rst     : std_logic := '1';
  signal en      : std_logic := '0';
  signal cnt_ce, cnt_and, cnt_icg : unsigned(7 downto 0);
  signal n_okien : natural := 0;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.bramkowanie
    port map (clk => clk, rst => rst, en => en, cnt_ce => cnt_ce, cnt_and => cnt_and, cnt_icg => cnt_icg);

  -- en z przerzutnika: zmienia się tuż po narastającym zboczu
  process (clk)
    variable s1, s2 : positive := 15;
    variable x      : real;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        en <= '0';
      else
        uniform(s1, s2, x);
        if x < 0.25 then
          en <= not en;
        end if;
      end if;
    end if;
  end process;

  process (en)
  begin
    if rising_edge(en) and rst = '0' then
      n_okien <= n_okien + 1;
    end if;
  end process;

  process
    variable errors : natural := 0;
    variable l      : line;
  begin
    for i in 1 to 3 loop
      wait until falling_edge(clk);
    end loop;
    rst <= '0';
    for k in 1 to 400 loop
      wait until falling_edge(clk);
      if cnt_icg /= cnt_ce then
        report "cnt_icg /= cnt_ce" severity warning;
        errors := errors + 1;
      end if;
      if cnt_and /= cnt_ce + to_unsigned(n_okien mod 256, 8) then
        report "cnt_and = " & integer'image(to_integer(cnt_and)) & ", oczekiwano " &
               integer'image(to_integer(cnt_ce + to_unsigned(n_okien mod 256, 8))) severity warning;
        errors := errors + 1;
      end if;
    end loop;
    write(l, "okien en=1: " & integer'image(n_okien) & ", cnt_ce=" & integer'image(to_integer(cnt_ce)) &
             ", cnt_and=" & integer'image(to_integer(cnt_and)) & ", cnt_icg=" & integer'image(to_integer(cnt_icg)));
    writeline(output, l);
    if n_okien < 10 then
      errors := errors + 1;
    end if;
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
