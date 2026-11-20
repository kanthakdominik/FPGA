-- Testbench 22.02: łącze źródłowo-synchroniczne DDR (PRBS7, 100 MHz, UI = 5 ns), kanał z opóźnieniem danych
-- 1 ns i zegara 1 ns + przesunięcie; monitor tSU = 1,0 ns i tH = 0,5 ns przy każdym zboczu odebranego zegara.
-- Przesunięcie 0-5 ns co 0,25 ns; oczekiwane okno od tSU do UI - tH, szerokość UI - tSU - tH.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity tb_ddr is
end entity tb_ddr;

architecture sim of tb_ddr is
  constant TSU  : time := 1000 ps;
  constant TH   : time := 500 ps;
  constant UI   : time := 5 ns;
  constant DANE : time := 1 ns;
  signal clk : std_logic := '0';
  signal fin : boolean := false;
  signal rst, rst_rx : std_logic := '1';
  signal bity, odebr : std_logic_vector(1 downto 0);
  signal tx_clk, tx_d : std_logic;
  signal rx_clk, rx_d : std_logic := '0';
  signal przes : time := 0 ns;
  signal bledy : std_logic_vector(15 downto 0);
  signal synch : std_logic;
  signal mon   : boolean := false;
  signal narusz : integer := 0;
begin
  clk <= not clk after 5 ns when not fin else clk;

  u_gen : entity work.prbs7 generic map (N => 2) port map (clk => clk, rst => rst, en => '1', q => bity);
  u_tx  : entity work.zs_nadajnik port map (clk => clk, dane => bity, tx_clk => tx_clk, tx_d => tx_d);
  rx_d <= transport tx_d after DANE;                       -- kanał
  process (tx_clk)
  begin
    rx_clk <= transport tx_clk after DANE + przes;
  end process;
  u_rx  : entity work.zs_odbiornik port map (rx_clk => rx_clk, rx_d => rx_d, dane => odebr);
  u_spr : entity work.prbs7_spr generic map (N => 2)
    port map (clk => rx_clk, rst => rst_rx, en => '1', d => odebr, bledy => bledy, synch => synch);

  -- monitor tSU / tH (oba zbocza rx_clk próbkują)
  process (rx_d, rx_clk, mon)
    variable t_d, t_k : time := 0 ns;
    variable n : integer := 0;
  begin
    if mon'event and mon then n := 0; end if;
    if rx_d'event and rx_clk'event then
      if mon then n := n + 1; end if;
    elsif rx_d'event then
      if mon and now - t_k < TH then n := n + 1; end if;
    elsif rx_clk'event then
      if mon and now - t_d < TSU then n := n + 1; end if;
    end if;
    if rx_d'event then t_d := now; end if;
    if rx_clk'event then t_k := now; end if;
    narusz <= n;
  end process;

  process
    variable l : line;
    variable errors : integer := 0;
    variable pierwszy, ostatni : integer := -1;
    variable mapa : string(1 to 21);
  begin
    for q in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst <= '0';
    for k in 0 to 20 loop
      przes <= k * 250 ps;
      for q in 1 to 10 loop wait until falling_edge(clk); end loop;
      rst_rx <= '1';
      for q in 1 to 3 loop wait until falling_edge(clk); end loop;
      rst_rx <= '0';
      mon <= true;
      for q in 1 to 100 loop wait until falling_edge(clk); end loop;
      mon <= false;
      wait for 0 ns;
      if narusz = 0 and unsigned(bledy) = 0 and synch = '1' then
        mapa(k + 1) := '+';
        if pierwszy < 0 then pierwszy := k; end if;
        ostatni := k;
      else
        mapa(k + 1) := '.';
      end if;
    end loop;
    write(l, "przesuniecie zegara 0..5 ns co 0,25 ns (+ dobre): " & mapa); writeline(output, l);
    write(l, "okno: " & integer'image(pierwszy * 250) & " .. " & integer'image(ostatni * 250) & " ps, szerokosc "
          & integer'image((ostatni - pierwszy) * 250) & " ps (UI - tSU - tH = " & integer'image((UI - TSU - TH) / 1 ps)
          & " ps)");
    writeline(output, l);
    if pierwszy < 0 or pierwszy * 250 ps /= TSU or ostatni * 250 ps /= UI - TH then errors := errors + 1; end if;
    przes <= 2750 ps;
    for q in 1 to 10 loop wait until falling_edge(clk); end loop;
    rst_rx <= '1';
    for q in 1 to 3 loop wait until falling_edge(clk); end loop;
    rst_rx <= '0';
    for q in 1 to 1000 loop wait until falling_edge(clk); end loop;
    write(l, "srodek okna (2,75 ns): 2000 bitow, bledow PRBS " & integer'image(to_integer(unsigned(bledy))));
    writeline(output, l);
    if unsigned(bledy) /= 0 or synch /= '1' then errors := errors + 1; end if;
    if errors = 0 then write(l, string'("PASS"));
    else write(l, "FAIL: " & integer'image(errors) & " bledow"); end if;
    writeline(output, l);
    fin <= true;
    std.env.finish;
    wait;
  end process;
end architecture sim;
