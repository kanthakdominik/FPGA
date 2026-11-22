-- Testbench zadania 6 (VHDL): FIFO 16 × 8 b, losowe zapisy i odczyty w trzech fazach, model w tablicy; flagi,
-- dane i pokrycie (pełna, pusta, zapis przy pełnej, odczyt przy pustej).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_sync_fifo is
end entity;

architecture sim of tb_sync_fifo is
  signal clk         : std_logic := '0';
  signal fin         : boolean := false;
  signal rst         : std_logic := '1';
  signal wr_en       : std_logic := '0';
  signal rd_en       : std_logic := '0';
  signal wr_data     : std_logic_vector(7 downto 0) := (others => '0');
  signal rd_data     : std_logic_vector(7 downto 0);
  signal full, empty : std_logic;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 5 ns when not fin;

  dut : entity work.sync_fifo generic map (W => 8, AW => 4)
    port map (clk => clk, rst => rst, wr_en => wr_en, wr_data => wr_data, full => full, rd_en => rd_en,
              rd_data => rd_data, empty => empty);

  process
    type model_t is array (0 to 4095) of std_logic_vector(7 downto 0);
    variable model                          : model_t;
    variable s1, s2                         : positive := 9;
    variable r                              : real;
    variable faza, cnt, n_wr, n_rd, errors  : natural := 0;
    variable n_full, n_empty, n_wf, n_re    : natural := 0;
    variable pending                        : boolean := false;
    variable exp_data                       : std_logic_vector(7 downto 0);
    variable pw, pr                         : real;
    variable e_full, e_empty                : std_logic;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 0 to 2999 loop
      wait until falling_edge(clk);
      faza := (i / 200) mod 3;
      if faza = 0 then pw := 0.8; pr := 0.2; elsif faza = 1 then pw := 0.2; pr := 0.8; else pw := 0.5; pr := 0.5; end if;
      uniform(s1, s2, r);
      if r < pw then wr_en <= '1'; else wr_en <= '0'; end if;
      uniform(s1, s2, r);
      if r < pr then rd_en <= '1'; else rd_en <= '0'; end if;
      uniform(s1, s2, r);
      wr_data <= std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
      wait until rising_edge(clk);
      if pending and rd_data /= exp_data then
        say("zle dane w " & time'image(now)); errors := errors + 1;
      end if;
      pending := false;
      cnt := n_wr - n_rd;
      if cnt = 16 then e_full := '1'; else e_full := '0'; end if;
      if cnt = 0 then e_empty := '1'; else e_empty := '0'; end if;
      if full /= e_full or empty /= e_empty then
        say("zle flagi w " & time'image(now)); errors := errors + 1;
      end if;
      if full = '1' then n_full := n_full + 1; end if;
      if empty = '1' then n_empty := n_empty + 1; end if;
      if wr_en = '1' and full = '1' then n_wf := n_wf + 1; end if;
      if rd_en = '1' and empty = '1' then n_re := n_re + 1; end if;
      if rd_en = '1' and cnt > 0 then
        exp_data := model(n_rd mod 4096);
        pending  := true;
        n_rd     := n_rd + 1;
      end if;
      if wr_en = '1' and cnt < 16 then
        model(n_wr mod 4096) := wr_data;
        n_wr := n_wr + 1;
      end if;
    end loop;
    say("zapisanych " & integer'image(n_wr) & ", odczytanych " & integer'image(n_rd) & "; taktow z full " &
        integer'image(n_full) & ", z empty " & integer'image(n_empty) & "; zapisow przy full " & integer'image(n_wf) &
        ", odczytow przy empty " & integer'image(n_re));
    if n_full = 0 or n_empty = 0 or n_wf = 0 or n_re = 0 then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
