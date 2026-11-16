-- Testbench tick_gen (DIV = 5 i 7) i bcd_counter (3 cyfry): okres impulsów, wartość licznika
-- porównana z liczbą całkowitą modulo 1000, przeniesienie przy przejściu 999 -> 000.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_counters is
end entity tb_counters;

architecture sim of tb_counters is
  signal clk   : std_logic := '0';
  signal done  : boolean   := false;
  signal rst   : std_logic := '1';
  signal en    : std_logic := '0';
  signal tick5, tick7, carry : std_logic;
  signal bcd   : std_logic_vector(11 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  u_t5  : entity work.tick_gen    generic map (DIV => 5)    port map (clk => clk, rst => rst, tick => tick5);
  u_t7  : entity work.tick_gen    generic map (DIV => 7)    port map (clk => clk, rst => rst, tick => tick7);
  u_bcd : entity work.bcd_counter generic map (DIGITS => 3)
    port map (clk => clk, rst => rst, en => en, bcd => bcd, carry => carry);

  stim : process
    variable errors       : natural  := 0;
    variable l            : line;
    variable value        : natural  := 0;
    variable carries      : natural  := 0;
    variable seed1, seed2 : positive := 11;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure check;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 1 to 1500 loop
      wait until falling_edge(clk);                            -- po n-tym zboczu od zdjęcia resetu
      if en = '1' then
        value := (value + 1) mod 1000;
      end if;
      check((tick5 = '1') = (n mod 5 = 0) and (tick7 = '1') = (n mod 7 = 0), "tick w takcie " & integer'image(n));
      check(to_integer(unsigned(bcd(11 downto 8))) = value / 100
            and to_integer(unsigned(bcd(7 downto 4))) = value / 10 mod 10
            and to_integer(unsigned(bcd(3 downto 0))) = value mod 10,
            "bcd=" & to_hstring(bcd) & ", oczekiwano " & integer'image(value));
      if rnd(4) /= 0 then                                      -- zezwolenie w 3/4 taktów
        en <= '1';
      else
        en <= '0';
      end if;
      wait for 1 ns;
      check((carry = '1') = (en = '1' and value = 999), "carry przy " & integer'image(value));
      if carry = '1' then
        carries := carries + 1;
      end if;
    end loop;

    check(carries > 0, "test nie osiagnal przepelnienia licznika");
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process stim;
end architecture sim;
