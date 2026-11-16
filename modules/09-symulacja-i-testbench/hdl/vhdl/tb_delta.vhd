-- Demonstracja delta cykli w symulatorze VHDL — testbench bez układu badanego.
-- Sprawdza zachowania wynikające ze standardu (IEEE 1076, cykl symulacji):
--   1. zamiana dwóch sygnałów w dwóch procesach działa — nowe wartości sygnałów są widoczne dopiero
--      w następnym delta cyklu, więc oba procesy czytają wartości sprzed zbocza,
--   2. zmienna zmienia się od razu, sygnał — po zakończeniu procesu (proces czyta starą wartość sygnału),
--   3. ZAGROŻENIE: rejestr taktowany „kopią zegara” (clk_copy <= clk) dostaje NOWĄ wartość rejestru z clk,
--      bo clk_copy zmienia się w tym samym delta cyklu co wyjście rejestru. W Verilogu ten sam zapis
--      działa poprawnie (tb_delta.v) — w VHDL nie przypisuj zegarów do innych sygnałów.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_delta is
end entity tb_delta;

architecture sim of tb_delta is
  signal clk      : std_logic := '0';
  signal done     : boolean   := false;
  signal a        : natural   := 1;                            -- 1. zamiana
  signal b        : natural   := 2;
  signal s        : natural   := 0;                            -- 2. sygnał i zmienna
  signal s_seen   : natural   := 0;
  signal v_seen   : natural   := 0;
  signal clk_copy : std_logic;                                 -- 3. zegar pochodny
  signal q, q2    : natural   := 0;
begin
  clk <= not clk after 5 ns when not done;

  p_a : process (clk)
  begin
    if rising_edge(clk) then
      a <= b;
    end if;
  end process p_a;

  p_b : process (clk)
  begin
    if rising_edge(clk) then
      b <= a;
    end if;
  end process p_b;

  p_sv : process (clk)
    variable v : natural := 0;
  begin
    if rising_edge(clk) then
      v      := v + 1;                                         -- od razu nowa wartość
      s      <= s + 1;                                         -- nowa wartość dopiero po procesie
      s_seen <= s;                                             -- proces widzi starą wartość s
      v_seen <= v;
    end if;
  end process p_sv;

  clk_copy <= clk;                                             -- o jeden delta cykl później niż clk

  p_q : process (clk)
  begin
    if rising_edge(clk) then
      q <= q + 1;
    end if;
  end process p_q;

  p_q2 : process (clk_copy)
  begin
    if rising_edge(clk_copy) then
      q2 <= q;                                                 -- q jest już nowe!
    end if;
  end process p_q2;

  check : process
    variable errors : natural := 0;
    variable l      : line;
    procedure expect(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure expect;
  begin
    for n in 1 to 6 loop
      wait until falling_edge(clk);                            -- po n-tym zboczu narastającym
      if n mod 2 = 1 then
        expect(a = 2 and b = 1, "zamiana sygnalow nie zadzialala, zbocze " & integer'image(n));
      else
        expect(a = 1 and b = 2, "zamiana sygnalow nie zadzialala, zbocze " & integer'image(n));
      end if;
      expect(v_seen = n and s_seen = n - 1 and s = n, "sygnal/zmienna, zbocze " & integer'image(n));
      expect(q = n and q2 = n, "zegar pochodny: q=" & integer'image(q) & " q2=" & integer'image(q2)
             & " - oczekiwano q2 = q (wyscig delta)");
    end loop;

    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process check;
end architecture sim;
