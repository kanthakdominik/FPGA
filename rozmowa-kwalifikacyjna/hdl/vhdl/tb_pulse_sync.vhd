-- Testbench zadania 7 (VHDL): szybka -> wolna (10 ns -> 27 ns) i wolna -> szybka; liczba impulsów i ich długość.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_pulse_sync is
end entity;

architecture sim of tb_pulse_sync is
  constant N           : positive := 60;
  signal clk_f, clk_s  : std_logic := '0';
  signal fin           : boolean := false;
  signal rst           : std_logic := '1';
  signal p_fs, p_sf    : std_logic := '0';
  signal q_fs, q_sf    : std_logic;
  signal got_fs, got_sf, sent_fs, sent_sf, err_s, err_f : natural := 0;
  signal done_fs, done_sf : boolean := false;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk_f <= not clk_f after 5 ns when not fin;
  clk_s <= not clk_s after 13.5 ns when not fin;

  u_fs : entity work.pulse_sync
    port map (clk_a => clk_f, rst_a => rst, pulse_a => p_fs, clk_b => clk_s, rst_b => rst, pulse_b => q_fs);
  u_sf : entity work.pulse_sync
    port map (clk_a => clk_s, rst_a => rst, pulse_a => p_sf, clk_b => clk_f, rst_b => rst, pulse_b => q_sf);

  -- odbiór i zliczanie po stronie B, nadane impulsy po stronie A
  process (clk_s)
    variable prev : std_logic := '0';
  begin
    if rising_edge(clk_s) then
      if q_fs = '1' then got_fs <= got_fs + 1; end if;
      if q_fs = '1' and prev = '1' then err_s <= err_s + 1; end if;
      prev := q_fs;
      if p_sf = '1' then sent_sf <= sent_sf + 1; end if;
    end if;
  end process;
  process (clk_f)
    variable prev : std_logic := '0';
  begin
    if rising_edge(clk_f) then
      if q_sf = '1' then got_sf <= got_sf + 1; end if;
      if q_sf = '1' and prev = '1' then err_f <= err_f + 1; end if;
      prev := q_sf;
      if p_fs = '1' then sent_fs <= sent_fs + 1; end if;
    end if;
  end process;

  nad_fs : process
  begin
    wait until rst = '0';
    for i in 1 to N loop
      wait until falling_edge(clk_f); p_fs <= '1';
      wait until falling_edge(clk_f); p_fs <= '0';
      for k in 1 to 11 loop wait until falling_edge(clk_f); end loop;
    end loop;
    done_fs <= true;
    wait;
  end process;

  nad_sf : process
  begin
    wait until rst = '0';
    for i in 1 to N loop
      wait until falling_edge(clk_s); p_sf <= '1';
      wait until falling_edge(clk_s); p_sf <= '0';
      for k in 1 to 2 loop wait until falling_edge(clk_s); end loop;
    end loop;
    done_sf <= true;
    wait;
  end process;

  process
    variable errors : natural := 0;
  begin
    wait for 100 ns;
    wait until falling_edge(clk_s);
    rst <= '0';
    wait until done_fs and done_sf;
    wait for 300 ns;
    say("szybka->wolna: wyslano " & integer'image(sent_fs) & ", odebrano " & integer'image(got_fs) &
        "; wolna->szybka: wyslano " & integer'image(sent_sf) & ", odebrano " & integer'image(got_sf));
    errors := err_s + err_f;
    if sent_fs /= N or got_fs /= N or sent_sf /= N or got_sf /= N then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
