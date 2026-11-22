-- Testbench zadania 9 (VHDL): 10 taktów na bit, odbiornik próbkujący na zboczu opadającym; bajty 0x55, 0xA3,
-- 0x00, 0xFF i 20 losowych, start w trakcie nadawania ignorowany.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity tb_uart_tx is
end entity;

architecture sim of tb_uart_tx is
  constant BIT_T : positive := 10;
  type bytes_t is array (0 to 63) of std_logic_vector(7 downto 0);
  signal clk       : std_logic := '0';
  signal fin       : boolean := false;
  signal rst       : std_logic := '1';
  signal start     : std_logic := '0';
  signal data      : std_logic_vector(7 downto 0) := (others => '0');
  signal ready, tx : std_logic;
  signal sent      : bytes_t;
  signal n_sent, n_got, err_rx : natural := 0;

  procedure say(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;
begin
  clk <= not clk after 500 ns when not fin;

  dut : entity work.uart_tx generic map (CLK_HZ => 1_000_000, BAUD => 100_000)
    port map (clk => clk, rst => rst, start => start, data => data, ready => ready, tx => tx);

  odbiornik : process
    variable len : natural;
    variable b   : std_logic_vector(7 downto 0);
  begin
    wait until falling_edge(tx);
    wait until falling_edge(clk);
    len := 0;
    while tx = '0' and len < 3 * BIT_T loop
      len := len + 1;
      wait until falling_edge(clk);
    end loop;
    if len /= BIT_T then say("bit startu " & integer'image(len) & " taktow"); err_rx <= err_rx + 1; end if;
    for i in 1 to BIT_T / 2 - 1 loop wait until falling_edge(clk); end loop;
    for k in 0 to 7 loop
      b(k) := tx;
      for i in 1 to BIT_T loop wait until falling_edge(clk); end loop;
    end loop;
    if tx /= '1' then say("brak bitu stopu"); err_rx <= err_rx + 1; end if;
    if b /= sent(n_got) then say("zly bajt"); err_rx <= err_rx + 1; end if;
    n_got <= n_got + 1;
  end process;

  process
    variable s1, s2 : positive := 4;
    variable r      : real;
    variable errors : natural := 0;

    procedure send(v : std_logic_vector(7 downto 0)) is
    begin
      wait until falling_edge(clk);
      while ready = '0' loop wait until falling_edge(clk); end loop;
      data  <= v;
      start <= '1';
      sent(n_sent) <= v;
      n_sent <= n_sent + 1;
      wait until falling_edge(clk);
      start <= '0';
    end procedure;
  begin
    for i in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for i in 1 to 5 loop wait until falling_edge(clk); end loop;
    send(x"55"); send(x"A3"); send(x"00"); send(x"FF");
    for i in 1 to 30 loop wait until falling_edge(clk); end loop;
    data <= x"77"; start <= '1';
    wait until falling_edge(clk);
    start <= '0';
    for i in 0 to 19 loop
      uniform(s1, s2, r);
      send(std_logic_vector(to_unsigned(integer(floor(r * 256.0)), 8)));
    end loop;
    wait until falling_edge(clk);
    while ready = '0' loop wait until falling_edge(clk); end loop;
    for i in 1 to 2 * BIT_T loop wait until falling_edge(clk); end loop;
    say("wyslanych " & integer'image(n_sent) & ", odebranych " & integer'image(n_got));
    errors := err_rx;
    if n_got /= n_sent then errors := errors + 1; end if;
    if errors = 0 then say("PASS"); else say("FAIL: " & integer'image(errors) & " bledow"); end if;
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture;
