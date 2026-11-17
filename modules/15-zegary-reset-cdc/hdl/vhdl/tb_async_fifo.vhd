-- Testbench async_fifo (W = 8, głębokość 16): zapis 100 MHz, odczyt 72,99 MHz, 4000 słów. Fazy: zapis
-- szybszy od odczytu (kolejka się zapełnia), odczyt szybszy (opróżnia się), po równo. Sprawdzane: kolejność
-- i wartości (model w tablicy), brak przepełnienia (zapisane - odczytane <= 16) i odczytu z pustej,
-- pokrycie: wr_full i rd_empty osiągnięte, zapis odrzucony przy pełnej.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_async_fifo is
end entity tb_async_fifo;

architecture sim of tb_async_fifo is
  constant W     : positive := 8;
  constant AW    : positive := 4;
  constant DEPTH : positive := 16;
  constant N     : positive := 4000;
  subtype slowo is std_logic_vector(W - 1 downto 0);
  type model_t is array (0 to N - 1) of slowo;

  signal wr_clk, rd_clk   : std_logic := '0';
  signal fin              : boolean   := false;
  signal wr_rst, rd_rst   : std_logic := '1';
  signal wr_en, rd_en     : std_logic := '0';
  signal wr_data          : slowo := (others => '0');
  signal rd_data          : slowo;
  signal wr_full, rd_empty : std_logic;
  signal model            : model_t;
  signal n_wr, n_rd, n_full, n_empty, n_odrz, err_w, err_r : natural := 0;
  signal faza             : natural := 0;
begin
  wr_clk <= not wr_clk after 5 ns when not fin;
  rd_clk <= not rd_clk after 6.85 ns when not fin;

  dut : entity work.async_fifo
    generic map (W => W, AW => AW)
    port map (wr_clk => wr_clk, wr_rst => wr_rst, wr_en => wr_en, wr_data => wr_data, wr_full => wr_full,
              rd_clk => rd_clk, rd_rst => rd_rst, rd_en => rd_en, rd_data => rd_data, rd_empty => rd_empty);

  process (wr_clk)
    variable s1, s2 : positive := 5;
    variable x      : real;
    variable p      : real;
  begin
    if falling_edge(wr_clk) then
      if faza = 0 then p := 0.9; elsif faza = 1 then p := 0.2; else p := 0.5; end if;
      uniform(s1, s2, x);
      if wr_rst = '0' and n_wr < N and x < p then wr_en <= '1'; else wr_en <= '0'; end if;
      uniform(s1, s2, x);
      wr_data <= std_logic_vector(to_unsigned(integer(floor(x * 256.0)), W));
    end if;
    if rising_edge(wr_clk) and wr_rst = '0' then
      if wr_en = '1' and wr_full = '0' then
        model(n_wr) <= wr_data;
        n_wr <= n_wr + 1;
      end if;
      if wr_en = '1' and wr_full = '1' then n_odrz <= n_odrz + 1; end if;
      if wr_full = '1' then n_full <= n_full + 1; end if;
      if n_wr - n_rd > DEPTH then err_w <= err_w + 1; end if;
    end if;
  end process;

  process (rd_clk)
    variable s1, s2 : positive := 6;
    variable x      : real;
    variable p      : real;
  begin
    if falling_edge(rd_clk) then
      if faza = 0 then p := 0.2; elsif faza = 1 then p := 0.9; else p := 0.5; end if;
      uniform(s1, s2, x);
      if rd_rst = '0' and x < p then rd_en <= '1'; else rd_en <= '0'; end if;
    end if;
    if rising_edge(rd_clk) and rd_rst = '0' then
      if rd_empty = '1' then n_empty <= n_empty + 1; end if;
      if rd_en = '1' and rd_empty = '0' then
        if n_rd >= n_wr then
          report "odczyt z pustej" severity warning;
          err_r <= err_r + 1;
        elsif rd_data /= model(n_rd) then
          report "zle dane" severity warning;
          err_r <= err_r + 1;
        end if;
        n_rd <= n_rd + 1;
      end if;
    end if;
  end process;

  process
    variable l      : line;
    variable errors : natural;
  begin
    wait for 100 ns;
    wait until falling_edge(wr_clk);
    wr_rst <= '0';
    wait until falling_edge(rd_clk);
    rd_rst <= '0';
    while n_rd < N loop
      wait for 2000 ns;
      faza <= (faza + 1) mod 3;
      exit when now > 2 ms;
    end loop;
    write(l, "zapisanych " & integer'image(n_wr) & ", odczytanych " & integer'image(n_rd) & "; taktow z wr_full " &
             integer'image(n_full) & ", z rd_empty " & integer'image(n_empty) & ", zapisow odrzuconych " &
             integer'image(n_odrz));
    writeline(output, l);
    errors := err_w + err_r;
    if n_full = 0 or n_empty = 0 or n_odrz = 0 or n_rd < N then errors := errors + 1; end if;
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
