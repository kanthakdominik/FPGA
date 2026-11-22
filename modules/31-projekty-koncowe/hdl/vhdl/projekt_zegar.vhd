-- Projekt 1 (31.01): zegar doby i stoper sterowane komendami przez UART 8N1 (uart_rx -> komendy -> zegar_stoper,
-- komendy -> uart_tx).
library ieee;
use ieee.std_logic_1164.all;

entity projekt_zegar is
  generic (CLK_HZ : positive := 50_000_000; BAUD : positive := 115_200; CS_DZIEL : positive := 500_000);
  port (
    clk, rst   : in  std_logic;
    rx         : in  std_logic;
    tx         : out std_logic;
    czas       : out std_logic_vector(23 downto 0);
    stoper     : out std_logic_vector(23 downto 0);
    biegnie    : out std_logic;
    pominieto  : out std_logic;
    blad_ramki : out std_logic
  );
end entity projekt_zegar;

architecture rtl of projekt_zegar is
  signal rx_dane, tx_dane : std_logic_vector(7 downto 0);
  signal rx_wazne, tx_start, tx_gotowy, ustaw, st_start, st_stop, st_zeruj, st_okr : std_logic;
  signal ustaw_czas, cz, st : std_logic_vector(23 downto 0);
begin
  czas <= cz; stoper <= st;
  u_rx : entity work.uart_rx generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
    port map (clk => clk, rst => rst, rx => rx, dane => rx_dane, wazne => rx_wazne, blad_ramki => blad_ramki,
              blad_parz => open);
  u_zs : entity work.zegar_stoper generic map (CS_DZIEL => CS_DZIEL)
    port map (clk => clk, rst => rst, ustaw => ustaw, ustaw_czas => ustaw_czas, st_start => st_start,
              st_stop => st_stop, st_zeruj => st_zeruj, st_okr => st_okr, czas => cz, stoper => st, okr => open,
              biegnie => biegnie, tik_cs => open);
  u_kom : entity work.komendy
    port map (clk => clk, rst => rst, rx_dane => rx_dane, rx_wazne => rx_wazne, czas => cz, stoper => st,
              ustaw => ustaw, ustaw_czas => ustaw_czas, st_start => st_start, st_stop => st_stop,
              st_zeruj => st_zeruj, st_okr => st_okr, tx_start => tx_start, tx_dane => tx_dane,
              tx_gotowy => tx_gotowy, pominieto => pominieto);
  u_tx : entity work.uart_tx generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
    port map (clk => clk, rst => rst, start => tx_start, dane => tx_dane, gotowy => tx_gotowy, tx => tx);
end architecture rtl;
