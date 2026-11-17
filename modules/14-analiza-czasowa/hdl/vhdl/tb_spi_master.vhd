-- Testbench spi_master (DIV = 2): 100 bajtów z modelem urządzenia podrzędnego SPI w trybie 0.
-- Sprawdzane: bajt odebrany przez urządzenie = wysłany, bajt odebrany przez nadajnik = wysłany przez
-- urządzenie, okres sclk = 2*DIV taktów, MOSI stabilne co najmniej pół okresu przed i po narastającym
-- zboczu sclk (zapas setup i hold po stronie urządzenia), sclk = '0' przy aktywacji cs_n.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_spi_master is
end entity tb_spi_master;

architecture sim of tb_spi_master is
  constant DIV  : positive := 2;
  constant TCLK : time     := 10 ns;
  constant HALF : time     := DIV * TCLK;

  signal clk   : std_logic := '0';
  signal fin   : boolean   := false;
  signal rst   : std_logic := '1';
  signal start : std_logic := '0';
  signal tx    : std_logic_vector(7 downto 0) := (others => '0');
  signal rx    : std_logic_vector(7 downto 0);
  signal busy, done, sclk, mosi, cs_n : std_logic;
  signal miso  : std_logic := '0';

  -- model urządzenia podrzędnego
  signal s_tx    : std_logic_vector(7 downto 0) := (others => '0');
  signal s_rx    : std_logic_vector(7 downto 0) := (others => '0');
  signal n_bits  : natural := 0;
  signal s_errs  : natural := 0;
begin
  clk <= not clk after TCLK / 2 when not fin;

  dut : entity work.spi_master
    generic map (DIV => DIV)
    port map (clk => clk, rst => rst, start => start, tx => tx, busy => busy, done => done, rx => rx,
              sclk => sclk, mosi => mosi, cs_n => cs_n, miso => miso);

  slave : process (cs_n, sclk, mosi)
    variable sh     : std_logic_vector(7 downto 0);
    variable t_mosi : time := 0 ns;
    variable t_rise : time := 0 ns;
    variable bits   : natural := 0;
  begin
    if falling_edge(cs_n) then
      if sclk /= '0' then
        s_errs <= s_errs + 1;
      end if;
      sh     := s_tx;
      miso   <= sh(7);
      bits   := 0;
      t_rise := 0 ns;
      t_mosi := now;
    end if;
    if cs_n = '0' and rising_edge(sclk) then
      if now - t_mosi < HALF then
        report "MOSI zmienione za pozno (setup)" severity warning;
        s_errs <= s_errs + 1;
      end if;
      if t_rise /= 0 ns and now - t_rise /= 2 * HALF then
        report "zly okres sclk" severity warning;
        s_errs <= s_errs + 1;
      end if;
      t_rise := now;
      s_rx   <= s_rx(6 downto 0) & mosi;
      bits   := bits + 1;
      n_bits <= bits;
    end if;
    if cs_n = '0' and falling_edge(sclk) then
      sh   := sh(6 downto 0) & '0';
      miso <= sh(7);
    end if;
    if mosi'event and cs_n = '0' then
      if t_rise /= 0 ns and now - t_rise < HALF then
        report "MOSI zmienione za wczesnie (hold)" severity warning;
        s_errs <= s_errs + 1;
      end if;
      t_mosi := now;
    end if;
  end process;

  stim : process
    variable seed1, seed2 : positive := 6;
    variable x            : real;
    variable errors       : natural := 0;
    variable l            : line;

    impure function rnd8 return std_logic_vector is
    begin
      uniform(seed1, seed2, x);
      return std_logic_vector(to_unsigned(integer(floor(x * 256.0)), 8));
    end function;
  begin
    wait until falling_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';
    for k in 0 to 99 loop
      tx    <= rnd8;
      s_tx  <= rnd8;
      start <= '1';
      wait until falling_edge(clk);
      start <= '0';
      wait until done = '1';
      wait until falling_edge(clk);
      if rx /= s_tx or s_rx /= tx or n_bits /= 8 then
        report "bajt " & integer'image(k) & ": blad transmisji" severity warning;
        errors := errors + 1;
      end if;
      uniform(seed1, seed2, x);
      for i in 1 to integer(floor(x * 4.0)) loop
        wait until falling_edge(clk);
      end loop;
    end loop;
    errors := errors + s_errs;
    write(l, "bajtow: 100, okres sclk: " & integer'image(2 * DIV * 10) & " ns");
    writeline(output, l);
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
