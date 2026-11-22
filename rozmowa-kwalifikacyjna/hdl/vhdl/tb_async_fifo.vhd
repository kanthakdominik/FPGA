-- Testbench zadania 8 (VHDL): zapis 100 MHz, odczyt 73 MHz, 3000 słów w trzech fazach; kolejność, brak
-- przepełnienia i odczytu z pustej, pokrycie full i empty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_async_fifo is
end entity;

architecture sim of tb_async_fifo is
  constant N : positive := 3000;
  type model_t is array (0 to N - 1) of std_logic_vector(7 downto 0);
  signal wr_clk, rd_clk : std_logic := '0';
  signal fin            : boolean := false;
  signal wr_rst, rd_rst : std_logic := '1';
  signal wr_en, rd_en   : std_logic := '0';
  signal wr_data        : std_logic_vector(7 downto 0) := (others => '0');
  signal rd_data        : std_logic_vector(7 downto 0);
  signal full, empty    : std_logic;
  signal model          : model_t;
  signal n_wr, n_rd, n_full, n_empty, err_w, err_r, faza : natural := 0;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  wr_clk <= not wr_clk after 5 ns when not fin;
  rd_clk <= not rd_clk after 6.85 ns when not fin;

  dut : entity work.async_fifo generic map (W => 8, AW => 4)
    port map (wr_clk => wr_clk, wr_rst => wr_rst, wr_en => wr_en, wr_data => wr_data, full => full,
              rd_clk => rd_clk, rd_rst => rd_rst, rd_en => rd_en, rd_data => rd_data, empty => empty);

  process (wr_clk)
    variable s1, s2 : positive := 21;
    variable r, p   : real;
  begin
    if falling_edge(wr_clk) then
      if faza = 0 then p := 0.9; elsif faza = 1 then p := 0.2; else p := 0.5; end if;
      uniform(s1, s2, r);
      if wr_rst = '0' and n_wr < N and r < p then wr_en <= '1'; else wr_en <= '0'; end if;
      uniform(s1, s2, r);
      wr_data <= std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8));
    end if;
    if rising_edge(wr_clk) and wr_rst = '0' then
      if full = '1' then n_full <= n_full + 1; end if;
      if wr_en = '1' and full = '0' then
        model(n_wr) <= wr_data;
        n_wr <= n_wr + 1;
      end if;
      if n_wr - n_rd > 16 then err_w <= err_w + 1; end if;
    end if;
  end process;

  process (rd_clk)
    variable s1, s2   : positive := 22;
    variable r, p     : real;
    variable pending  : boolean := false;
    variable exp_data : std_logic_vector(7 downto 0);
  begin
    if falling_edge(rd_clk) then
      if faza = 0 then p := 0.2; elsif faza = 1 then p := 0.9; else p := 0.5; end if;
      uniform(s1, s2, r);
      if rd_rst = '0' and r < p then rd_en <= '1'; else rd_en <= '0'; end if;
    end if;
    if rising_edge(rd_clk) and rd_rst = '0' then
      if pending and rd_data /= exp_data then
        report "zle dane" severity warning;
        err_r <= err_r + 1;
      end if;
      pending := false;
      if empty = '1' then n_empty <= n_empty + 1; end if;
      if rd_en = '1' and empty = '0' then
        if n_rd >= n_wr then
          report "odczyt z pustej" severity warning;
          err_r <= err_r + 1;
        else
          exp_data := model(n_rd);
          pending  := true;
        end if;
        n_rd <= n_rd + 1;
      end if;
    end if;
  end process;

  process
    variable errors : natural;
  begin
    wait for 100 ns;
    wait until falling_edge(wr_clk);
    wr_rst <= '0';
    wait until falling_edge(rd_clk);
    rd_rst <= '0';
    while n_rd < N loop
      wait for 3000 ns;
      faza <= (faza + 1) mod 3;
      exit when now > 2 ms;
    end loop;
    for i in 1 to 3 loop wait until rising_edge(rd_clk); end loop;
    say("zapisanych " & integer'image(n_wr) & ", odczytanych " & integer'image(n_rd) & "; taktow z full " &
        integer'image(n_full) & ", z empty " & integer'image(n_empty));
    errors := err_w + err_r;
    if n_full = 0 or n_empty = 0 or n_rd < N then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
