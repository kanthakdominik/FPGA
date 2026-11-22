-- Projekt 3 (31.03): uart_rx -> midi_parser -> syntezator -> i2s_master. Jak w wersjach Verilog i SV.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity projekt_syntezator is
  generic (
    CLK_HZ : positive := 12_500_000; BAUD : positive := 31_250;
    A_KROK : natural := 268; D_KROK : natural := 5; S_POZ : natural := 39321; R_KROK : natural := 4
  );
  port (
    clk, rst   : in  std_logic;
    rx         : in  std_logic;
    bclk, wclk, dout : out std_logic;
    probka     : out signed(23 downto 0);
    nowa       : out std_logic;
    aktywne    : out std_logic_vector(3 downto 0);
    blad_ramki : out std_logic
  );
end entity projekt_syntezator;

architecture rtl of projekt_syntezator is
  signal rx_dane : std_logic_vector(7 downto 0);
  signal rx_wazne, ev_on, ev_off, ev_wsz, ev_prog, ramka : std_logic;
  signal nuta, vel : unsigned(6 downto 0);
  signal prog : unsigned(1 downto 0);
  signal p : signed(23 downto 0);
begin
  probka <= p;
  u_rx : entity work.uart_rx generic map (CLK_HZ => CLK_HZ, BAUD => BAUD)
    port map (clk => clk, rst => rst, rx => rx, dane => rx_dane, wazne => rx_wazne, blad_ramki => blad_ramki,
              blad_parz => open);
  u_midi : entity work.midi_parser
    port map (clk => clk, rst => rst, dane => rx_dane, wazne => rx_wazne, ev_on => ev_on, ev_off => ev_off,
              ev_wszystkie => ev_wsz, ev_prog => ev_prog, nuta => nuta, vel => vel, prog => prog);
  u_synt : entity work.syntezator
    generic map (A_KROK => A_KROK, D_KROK => D_KROK, S_POZ => S_POZ, R_KROK => R_KROK)
    port map (clk => clk, rst => rst, ramka => ramka, ev_on => ev_on, ev_off => ev_off, ev_wszystkie => ev_wsz,
              ev_prog => ev_prog, nuta => nuta, vel => vel, prog => prog, probka => p, nowa => nowa,
              aktywne => aktywne);
  u_i2s : entity work.i2s_master
    port map (clk => clk, rst => rst, tx_l => std_logic_vector(p), tx_p => std_logic_vector(p), rx_l => open,
              rx_p => open, ramka => ramka, bclk => bclk, wclk => wclk, dout => dout, din => '0');
end architecture rtl;
