-- Testbench debounce_fsm (N = 8): 30 naciśnięć z drganiami przy wciśnięciu i puszczeniu.
-- Model zapisany inaczej niż automat: licznik kolejnych taktów, w których wejście po synchronizacji różni się
-- od przyjętego poziomu; poziom zmienia się, gdy licznik osiągnie N + 1.
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_debounce_fsm is
end entity tb_debounce_fsm;

architecture sim of tb_debounce_fsm is
  constant N       : positive := 8;
  constant PRESSES : positive := 30;
  signal clk                    : std_logic := '0';
  signal done                   : boolean   := false;
  signal rst                    : std_logic := '1';
  signal btn                    : std_logic := '0';
  signal raw, level, rise, fall : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.debounce_fsm generic map (N => N)
    port map (clk => clk, rst => rst, btn => btn, raw => raw, level => level, rise => rise, fall => fall);

  stim : process
    variable m1, m2, lvl             : std_logic := '0';
    variable run, errors, rises      : natural   := 0;
    variable falls, raw_edges        : natural   := 0;
    variable l                       : line;
    variable seed1, seed2            : positive  := 41;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;

    procedure cycle(value : std_logic) is                      -- jeden takt z danym btn; sprawdzenie po zboczu
      variable e_rise, e_fall : std_logic := '0';
    begin
      btn <= value;
      wait until falling_edge(clk);
      if m2 /= lvl then                                        -- model zbocza: automat widział stare m2
        run := run + 1;
        if run = N + 1 then
          lvl := m2;  run := 0;  e_rise := m2;  e_fall := not m2;
        end if;
      else
        run := 0;
      end if;
      if m1 = '1' and m2 = '0' then
        raw_edges := raw_edges + 1;
      end if;
      m2 := m1;
      m1 := value;
      if raw /= m2 or level /= lvl or rise /= e_rise or fall /= e_fall then
        errors := errors + 1;
        report "raw/level/rise/fall = " & to_string(raw) & to_string(level) & to_string(rise) & to_string(fall)
             & ", oczekiwano " & to_string(m2) & to_string(lvl) & to_string(e_rise) & to_string(e_fall) severity warning;
      end if;
      if rise = '1' then rises := rises + 1; end if;
      if fall = '1' then falls := falls + 1; end if;
    end procedure cycle;

    procedure bounce_then(value : std_logic) is               -- kilka krótkich drgań, potem stały poziom
      variable nb : natural;
    begin
      nb := rnd(6);
      for b in 1 to nb loop
        for c in 0 to rnd(N - 2) loop
          cycle(value);
        end loop;
        for c in 0 to rnd(N - 2) loop
          cycle(not value);
        end loop;
      end loop;
      for c in 1 to N + 3 + rnd(2 * N) loop
        cycle(value);
      end loop;
    end procedure bounce_then;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for c in 1 to 5 loop
      cycle('0');
    end loop;
    for p in 1 to PRESSES loop
      bounce_then('1');                                        -- wciśnięcie
      bounce_then('0');                                        -- puszczenie
    end loop;

    write(l, "nacisniecia: " & integer'image(PRESSES) & ", impulsy rise: " & integer'image(rises)
           & ", zbocza raw: " & integer'image(raw_edges));
    writeline(output, l);
    if rises /= PRESSES or falls /= PRESSES then
      errors := errors + 1;
      report "liczba rise/fall rozna od liczby nacisniec" severity warning;
    end if;
    if raw_edges <= PRESSES then
      errors := errors + 1;
      report "test nie wygenerowal drgan" severity warning;
    end if;
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
