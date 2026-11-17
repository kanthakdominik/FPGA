-- Testbench fifo_sync: 3000 taktów losowych zapisów i odczytów w trzech fazach (napełnianie, równowaga,
-- opróżnianie), model w buforze cyklicznym. W każdym takcie sprawdzane: count, full, empty i rd_data
-- (najstarszy element). Pokrycie: pełna, pusta po pełnej, jednoczesny zapis i odczyt, zapis odrzucony.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_fifo_sync is
end entity tb_fifo_sync;

architecture sim of tb_fifo_sync is
  constant W     : positive := 8;
  constant AW    : positive := 3;
  constant DEPTH : positive := 8;

  signal clk     : std_logic := '0';
  signal done    : boolean   := false;
  signal rst     : std_logic := '1';
  signal wr_en   : std_logic := '0';
  signal rd_en   : std_logic := '0';
  signal wr_data : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal rd_data : std_logic_vector(W - 1 downto 0);
  signal full    : std_logic;
  signal empty   : std_logic;
  signal count   : unsigned(AW downto 0);
begin
  clk <= not clk after 5 ns when not done;

  dut : entity work.fifo_sync
    generic map (W => W, AW => AW)
    port map (clk => clk, rst => rst, wr_en => wr_en, wr_data => wr_data, full => full, rd_en => rd_en,
              rd_data => rd_data, empty => empty, count => count);

  process
    type q_t is array (0 to DEPTH - 1) of std_logic_vector(W - 1 downto 0);
    variable q                    : q_t;
    variable head, size           : natural := 0;
    variable errors, n_full       : natural := 0;
    variable n_empty_after_full   : natural := 0;
    variable n_both, n_rejected   : natural := 0;
    variable was_full             : boolean := false;
    variable p_wr                 : natural;
    variable seed1, seed2         : positive := 31;
    variable r                    : real;
    variable l                    : line;
    variable exp_full, exp_empty  : std_logic;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for n in 0 to 2999 loop
      if n mod 600 < 200 then p_wr := 80; elsif n mod 600 < 400 then p_wr := 50; else p_wr := 20; end if;
      uniform(seed1, seed2, r);
      wr_en <= '1' when r * 100.0 < real(p_wr) else '0';
      uniform(seed1, seed2, r);
      rd_en <= '1' when r * 100.0 < real(100 - p_wr) else '0';
      uniform(seed1, seed2, r);
      wr_data <= std_logic_vector(to_unsigned(integer(floor(r * 256.0)), W));
      wait for 1 ns;
      exp_full  := '1' when size = DEPTH else '0';
      exp_empty := '1' when size = 0 else '0';
      if count /= size or full /= exp_full or empty /= exp_empty then
        report "takt " & integer'image(n) & ": count=" & integer'image(to_integer(count)) & ", model " &
               integer'image(size) severity warning;
        errors := errors + 1;
      end if;
      if size > 0 and rd_data /= q(head) then
        report "takt " & integer'image(n) & ": zle rd_data" severity warning;
        errors := errors + 1;
      end if;
      if full = '1' then n_full := n_full + 1; was_full := true; end if;
      if was_full and empty = '1' then n_empty_after_full := n_empty_after_full + 1; end if;
      if wr_en = '1' and full = '1' then n_rejected := n_rejected + 1; end if;
      if wr_en = '1' and rd_en = '1' and full = '0' and empty = '0' then n_both := n_both + 1; end if;
      if rd_en = '1' and size > 0 then
        head := (head + 1) mod DEPTH;
        size := size - 1;
      end if;
      if wr_en = '1' and full = '0' then
        q((head + size) mod DEPTH) := wr_data;
        size := size + 1;
      end if;
      wait until falling_edge(clk);
    end loop;
    if n_full = 0 or n_empty_after_full = 0 or n_both = 0 or n_rejected = 0 then
      report "pokrycie niepelne" severity warning;
      errors := errors + 1;
    end if;
    write(l, "taktow z pelna: " & integer'image(n_full) & ", zapisow odrzuconych: " & integer'image(n_rejected));
    writeline(output, l);
    if errors = 0 then
      write(l, string'("PASS"));
    else
      write(l, "FAIL: " & integer'image(errors) & " bledow");
    end if;
    writeline(output, l);
    done <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
