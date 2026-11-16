-- Testbench pack4: losowe valid po stronie bajtów, losowe ready po stronie słów (z okresem silnego
-- przeciążenia), na końcu pełna przepustowość. Sprawdzane: kolejność i zawartość słów (model — tablica bajtów),
-- stabilność m_valid/m_data przy wstrzymaniu, brak zgubionych słów, s_ready = '1' przy pełnym przepływie.
-- Źródło przestrzega zasady: raz podane valid i dane trzyma do przesłania.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_pack4 is
end entity tb_pack4;

architecture sim of tb_pack4 is
  signal clk              : std_logic := '0';
  signal done             : boolean   := false;
  signal rst              : std_logic := '1';
  signal s_valid, m_ready : std_logic := '0';
  signal s_ready, m_valid : std_logic;
  signal s_data           : std_logic_vector(7 downto 0) := x"00";
  signal m_data           : std_logic_vector(31 downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.pack4
    port map (clk => clk, rst => rst, s_data => s_data, s_valid => s_valid, s_ready => s_ready,
              m_data => m_data, m_valid => m_valid, m_ready => m_ready);

  stim : process
    type bytes_t is array (0 to 8191) of std_logic_vector(7 downto 0);
    variable bytes                    : bytes_t;
    variable held, e                  : std_logic_vector(31 downto 0);
    variable stalled, pending         : boolean  := false;
    variable nin, nout, errors        : natural  := 0;
    variable backpressure             : natural  := 0;
    variable l                        : line;
    variable seed1, seed2             : positive := 53;

    impure function rnd(n : positive) return natural is      -- liczba losowa 0 .. n - 1
      variable r : real;
    begin
      uniform(seed1, seed2, r);
      return integer(floor(r * real(n)));
    end function rnd;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 2599 loop
      -- 1. reguła wstrzymania: słowo niewzięte w poprzednim takcie musi stać bez zmian
      if stalled and (m_valid /= '1' or m_data /= held) then
        errors := errors + 1;
        report "takt " & integer'image(n) & ": zmiana m_valid/m_data podczas wstrzymania" severity warning;
      end if;
      -- 2. nowe pobudzenia na ten takt
      if n < 1000 then
        m_ready <= '1' when rnd(2) = 1 else '0';
      elsif n < 1500 then
        m_ready <= '1' when rnd(8) = 0 else '0';                -- silne przeciążenie
      else
        m_ready <= '1';                                        -- pełny przepływ, opróżnianie
      end if;
      if not pending then                                      -- poprzedni bajt przesłany
        if n >= 2500 then
          s_valid <= '0';
        elsif n >= 1500 then
          s_valid <= '1';
        else
          s_valid <= '1' when rnd(4) /= 0 else '0';
        end if;
        s_data <= std_logic_vector(to_unsigned(rnd(256), 8));
      end if;
      wait for 1 ns;
      -- 3. przesłania w tym takcie
      if s_valid = '1' and s_ready = '1' then
        bytes(nin) := s_data;
        nin := nin + 1;
      end if;
      pending := s_valid = '1' and s_ready = '0';              -- bajt czeka — źródło trzyma valid i dane
      if pending then
        backpressure := backpressure + 1;
      end if;
      if n >= 1500 and n < 2500 and s_ready = '0' then
        errors := errors + 1;
        report "takt " & integer'image(n) & ": s_ready = 0 przy pelnym przeplywie" severity warning;
      end if;
      if m_valid = '1' and m_ready = '1' then
        if 4 * nout + 3 >= nin then
          errors := errors + 1;
          report "slowo " & integer'image(nout) & " przed przyjeciem 4 bajtow" severity warning;
        else
          e := bytes(4 * nout + 3) & bytes(4 * nout + 2) & bytes(4 * nout + 1) & bytes(4 * nout);
          if m_data /= e then
            errors := errors + 1;
            report "slowo " & integer'image(nout) & ": " & to_hstring(m_data) & ", oczekiwano " & to_hstring(e)
              severity warning;
          end if;
        end if;
        nout := nout + 1;
      end if;
      stalled := m_valid = '1' and m_ready = '0';
      held    := m_data;
      wait until falling_edge(clk);
    end loop;

    if nout /= nin / 4 then
      errors := errors + 1;
      report "odebrano " & integer'image(nout) & " slow z " & integer'image(nin) & " bajtow" severity warning;
    end if;
    if backpressure = 0 then
      errors := errors + 1;
      report "test nie sprawdzil wstrzymania po stronie bajtow" severity warning;
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
