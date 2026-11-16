-- Testbench reset_sync i reg_styles: asynchroniczne ustawienie i synchroniczne zdjęcie resetu,
-- różnica między resetem asynchronicznym, synchronicznym i rejestrem bez resetu.
library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_reset is
end entity tb_reset;

architecture sim of tb_reset is
  signal clk    : std_logic := '0';
  signal done   : boolean   := false;
  signal arst_n : std_logic := '0';
  signal arst   : std_logic := '0';
  signal srst   : std_logic := '0';
  signal rst    : std_logic;
  signal d                       : std_logic_vector(7 downto 0) := x"00";
  signal q_async, q_sync, q_none : std_logic_vector(7 downto 0);
begin
  clk <= not clk after 5 ns when not done;                     -- zbocza narastające w 5, 15, 25 … ns

  u_rs : entity work.reset_sync generic map (STAGES => 2) port map (clk => clk, arst_n => arst_n, rst => rst);
  u_rg : entity work.reg_styles generic map (W => 8)
    port map (clk => clk, arst => arst, srst => srst, d => d, q_async => q_async, q_sync => q_sync, q_none => q_none);

  stim : process
    variable errors : natural := 0;
    variable l      : line;
    procedure ensure(ok : boolean; msg : string) is
    begin
      if not ok then
        errors := errors + 1;
        report msg severity warning;
      end if;
    end procedure ensure;
  begin
    -- reset_sync
    wait for 1 ns;
    ensure(rst = '1', "brak resetu przed pierwszym zboczem");
    wait for 6 ns;
    arst_n <= '1';                                             -- t = 7 ns: zdjęcie między zboczami
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(rst = '1', "reset zdjety po 1 takcie");
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(rst = '0', "reset nie zdjety po 2 taktach");
    wait for 2 ns;
    arst_n <= '0';                                             -- ustawienie w środku taktu
    wait for 1 ns;
    ensure(rst = '1', "reset nie ustawiony asynchronicznie");
    wait until falling_edge(clk);
    arst_n <= '1';
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(rst = '1', "reset zdjety po 1 takcie (2)");
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(rst = '0', "reset nie zdjety po 2 taktach (2)");

    -- reg_styles
    wait until falling_edge(clk);
    d <= x"A5";
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(q_async = x"A5" and q_sync = x"A5" and q_none = x"A5", "zapis A5");
    arst <= '1';                                               -- reset asynchroniczny w środku taktu
    wait for 1 ns;
    ensure(q_async = x"00", "q_async nie wyzerowany bez zbocza");
    ensure(q_sync = x"A5" and q_none = x"A5", "reset asynchroniczny zmienil inne rejestry");
    wait until falling_edge(clk);
    arst <= '0';
    srst <= '1';
    d    <= x"3C";
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(q_async = x"3C" and q_sync = x"00" and q_none = x"3C", "reset synchroniczny");
    wait until falling_edge(clk);
    srst <= '0';
    d    <= x"5A";
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(q_async = x"5A" and q_sync = x"5A" and q_none = x"5A", "zapis 5A");
    srst <= '1';                                               -- reset synchroniczny bez zbocza
    wait for 1 ns;
    ensure(q_sync = x"5A", "q_sync wyzerowany bez zbocza");
    wait until rising_edge(clk);  wait for 1 ns;
    ensure(q_sync = x"00", "q_sync nie wyzerowany na zboczu");

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
