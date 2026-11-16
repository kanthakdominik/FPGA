-- Testbench linii opóźniającej: DEPTH = 3 (wyjście = wejście sprzed 3 taktów) i DEPTH = 0 (połączenie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_pipe_delay is
end entity tb_pipe_delay;

architecture sim of tb_pipe_delay is
  constant W     : positive := 8;
  constant DEPTH : natural  := 3;
  constant T     : time     := 10 ns;
  constant N     : natural  := 40;
  type data_array is array (0 to N - 1) of std_logic_vector(W - 1 downto 0);
  signal clk     : std_logic := '0';
  signal done    : boolean   := false;
  signal x       : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal y3, y0  : std_logic_vector(W - 1 downto 0);
begin
  clk <= not clk after T / 2 when not done;

  dut3 : entity work.pipe_delay
    generic map (W => W, DEPTH => DEPTH)
    port map (clk => clk, x => x, y => y3);
  dut0 : entity work.pipe_delay
    generic map (W => W, DEPTH => 0)
    port map (clk => clk, x => x, y => y0);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    variable hist   : data_array;
    variable lfsr   : unsigned(W - 1 downto 0) := x"A5";
    procedure check(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure;
  begin
    for k in 0 to N - 1 loop
      wait until falling_edge(clk);
      if k >= DEPTH then
        check(y3 = hist(k - DEPTH), "DEPTH=3: zla wartosc w takcie " & integer'image(k));
      end if;
      -- nowa wartość z rejestru LFSR (wielomian x^8 + x^6 + x^5 + x^4 + 1)
      lfsr    := lfsr(W - 2 downto 0) & (lfsr(7) xor lfsr(5) xor lfsr(4) xor lfsr(3));
      hist(k) := std_logic_vector(lfsr);
      x       <= std_logic_vector(lfsr);
      wait for 1 ns;
      check(y0 = std_logic_vector(lfsr), "DEPTH=0: wyjscie rozne od wejscia");
    end loop;

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
