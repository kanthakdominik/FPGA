-- Testbench 22.03: ser_tx (8:1) -> kanał z opóźnieniem 0-7 bitów -> deser_rx -> wyrownaj -> prbs7_spr.
-- Dla każdego opóźnienia: trening słowem 0x6B, wyrównanie poślizgami, potem 300 słów PRBS7 bez błędów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_serdes is
end entity tb_serdes;

architecture sim of tb_serdes is
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst, rst_spr, trening : std_logic := '1';
  signal dane_prbs, slowo_rx, slowo_tx, poslizgi : std_logic_vector(7 downto 0);
  signal pobierz, q, wazne, bitslip, wyrownane, synch, wej : std_logic;
  signal bledy : std_logic_vector(15 downto 0);
  signal linia : std_logic_vector(15 downto 0) := (others => '0');
  signal opozn : natural range 0 to 15 := 0;
begin
  clk <= not clk after 1 ns when not fin else clk;

  u_gen : entity work.prbs7 generic map (N => 8) port map (clk => clk, rst => rst, en => pobierz, q => dane_prbs);
  slowo_tx <= x"6B" when trening = '1' else dane_prbs;
  u_ser : entity work.ser_tx generic map (N => 8) port map (clk => clk, rst => rst, slowo => slowo_tx,
                                                             pobierz => pobierz, q => q);
  process (clk)
  begin
    if rising_edge(clk) then linia <= linia(14 downto 0) & q; end if;
  end process;
  wej <= q when opozn = 0 else linia(opozn - 1);
  u_des : entity work.deser_rx generic map (N => 8)
    port map (clk => clk, rst => rst, d => wej, bitslip => bitslip, slowo => slowo_rx, wazne => wazne);
  u_wyr : entity work.wyrownaj generic map (N => 8, WZOR => x"6B", ILE => 8)
    port map (clk => clk, rst => rst, slowo => slowo_rx, wazne => wazne, bitslip => bitslip, wyrownane => wyrownane,
              poslizgi => poslizgi);
  u_spr : entity work.prbs7_spr generic map (N => 8)
    port map (clk => clk, rst => rst_spr, en => wazne, d => slowo_rx, bledy => bledy, synch => synch);

  process
    variable l : line;
    variable errors, n : integer := 0;
  begin
    for d in 0 to 7 loop
      opozn   <= d;
      rst     <= '1';
      rst_spr <= '1';
      trening <= '1';
      for k in 1 to 20 loop wait until falling_edge(clk); end loop;
      rst <= '0';
      n := 0;
      while wyrownane /= '1' and n < 2000 loop
        wait until falling_edge(clk);
        n := n + 1;
      end loop;
      trening <= '0';
      for k in 1 to 8 * 6 loop wait until falling_edge(clk); end loop;
      rst_spr <= '0';
      for k in 1 to 8 * 300 loop wait until falling_edge(clk); end loop;
      write(l, "opoznienie " & integer'image(d) & " bit: wyrownanie po " & integer'image(to_integer(unsigned(poslizgi)))
            & " poslizgach, " & integer'image(n) & " bitow; bledy danych " & integer'image(to_integer(unsigned(bledy))));
      writeline(output, l);
      if wyrownane /= '1' or unsigned(bledy) /= 0 or synch /= '1' then errors := errors + 1; end if;
    end loop;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
