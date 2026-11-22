-- Testbench zadania 11 (VHDL): kolejne liczby z losowym s_valid i m_ready; kolejność, brak strat i dubli,
-- stabilność wyjścia bez m_ready, 100 przesłań w 100 taktach przy pełnym ruchu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_skid_buffer is
end entity;

architecture sim of tb_skid_buffer is
  signal clk     : std_logic := '0';
  signal fin     : boolean := false;
  signal rst     : std_logic := '1';
  signal s_valid : std_logic := '0';
  signal s_data  : std_logic_vector(7 downto 0) := (others => '0');
  signal s_ready : std_logic;
  signal m_valid : std_logic;
  signal m_data  : std_logic_vector(7 downto 0);
  signal m_ready : std_logic := '0';

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.skid_buffer generic map (W => 8)
    port map (clk => clk, rst => rst, s_valid => s_valid, s_ready => s_ready, s_data => s_data,
              m_valid => m_valid, m_ready => m_ready, m_data => m_data);

  process
    variable s1, s2                   : positive := 2;
    variable r                        : real;
    variable n_sent, n_got, errors    : natural := 0;
    variable full_rate, n_full_rate   : natural := 0;
    variable tryb                     : natural := 0;
    variable s_acc, stall             : boolean := false;
    variable data_p                   : std_logic_vector(7 downto 0);
    variable v_valid                  : std_logic := '0';
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 2199 loop
      -- tryb: 0 losowo, 1 pełny ruch (takty 1500..1604), 2 koniec źródła
      if i = 1500 then tryb := 1; elsif i = 1605 then tryb := 0; elsif i = 2100 then tryb := 2; end if;
      wait until falling_edge(clk);
      if s_acc or v_valid = '0' then
        uniform(s1, s2, r);
        if tryb = 1 then v_valid := '1'; elsif tryb = 2 then v_valid := '0';
        elsif r < 0.7 then v_valid := '1'; else v_valid := '0'; end if;
        s_valid <= v_valid;
        s_data  <= std_logic_vector(to_unsigned(n_sent mod 256, 8));
      end if;
      uniform(s1, s2, r);
      if tryb /= 0 or r < 0.6 then m_ready <= '1'; else m_ready <= '0'; end if;
      wait until rising_edge(clk);
      s_acc := s_valid = '1' and s_ready = '1';
      if s_acc then n_sent := n_sent + 1; end if;
      if stall and (m_valid = '0' or m_data /= data_p) then
        say("wyjscie zmienilo sie bez m_ready"); errors := errors + 1;
      end if;
      if m_valid = '1' and m_ready = '1' then
        if to_integer(unsigned(m_data)) /= n_got mod 256 then say("zla kolejnosc"); errors := errors + 1; end if;
        n_got := n_got + 1;
        if i >= 1505 and i < 1605 then n_full_rate := n_full_rate + 1; end if;
      end if;
      stall  := m_valid = '1' and m_ready = '0';
      data_p := m_data;
    end loop;
    say("wyslanych " & integer'image(n_sent) & ", odebranych " & integer'image(n_got) &
        "; przeslan w 100 taktach przy pelnym ruchu: " & integer'image(n_full_rate));
    if n_sent /= n_got or n_full_rate /= 100 then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
