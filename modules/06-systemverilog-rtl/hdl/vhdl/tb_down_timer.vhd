-- Testbench timera: zezwolenie pseudolosowe, przeładowania period w trakcie pracy, porównanie z modelem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_down_timer is
end entity tb_down_timer;

architecture sim of tb_down_timer is
  constant W  : positive  := 8;
  signal clk  : std_logic := '0';
  signal done : boolean   := false;
  signal rst  : std_logic := '1';
  signal en, load : std_logic := '0';
  signal period   : std_logic_vector(W - 1 downto 0) := x"04";
  signal count    : std_logic_vector(W - 1 downto 0);
  signal tick     : std_logic;
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.down_timer
    generic map (W => W)
    port map (clk => clk, rst => rst, en => en, load => load, period => period, count => count, tick => tick);

  stim : process
    variable errors  : natural := 0;
    variable l       : line;
    variable ticks   : natural := 0;
    variable m_count : natural := 0;
    variable m_tick  : std_logic := '0';
    variable m_per   : natural := 4;
    variable v_en, v_load : std_logic;
    variable lfsr    : unsigned(15 downto 0) := x"BEEF";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    wait until falling_edge(clk);
    rst <= '0';
    for k in 0 to 299 loop
      check(to_integer(unsigned(count)) = m_count and tick = m_tick, "takt " & integer'image(k));
      if tick = '1' then
        ticks := ticks + 1;
      end if;
      if lfsr(0) = '1' then
        lfsr := shift_right(lfsr, 1) xor x"B400";
      else
        lfsr := shift_right(lfsr, 1);
      end if;
      v_en   := lfsr(0) or lfsr(1);
      v_load := '0';
      if k = 100 then
        v_load := '1'; m_per := 2;
      elsif k = 200 then
        v_load := '1'; m_per := 0;
      end if;
      en     <= v_en;
      load   <= v_load;
      period <= std_logic_vector(to_unsigned(m_per, W));
      m_tick := '0';
      if v_load = '1' then
        m_count := m_per;
      elsif v_en = '1' then
        if m_count = 0 then
          m_count := m_per;
          m_tick  := '1';
        else
          m_count := m_count - 1;
        end if;
      end if;
      wait until falling_edge(clk);
    end loop;
    check(ticks >= 20, "za malo impulsow tick");

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
