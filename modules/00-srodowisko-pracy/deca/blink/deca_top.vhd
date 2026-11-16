-- Moduł nadrzędny dla płytki DECA — VHDL.
-- LED(0) miga z częstotliwością 1 Hz, LED(1) z 4 Hz. KEY(0) (wciśnięty = '0') zeruje liczniki.
-- Diody DECA świecą przy stanie niskim, więc wyjścia są odwrócone.
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in  std_logic;                     -- 50 MHz, pin M8
    KEY           : in  std_logic_vector(1 downto 0);  -- przyciski, wciśnięty = '0'
    LED           : out std_logic_vector(7 downto 0)   -- diody, '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  -- synchronizacja przycisku z zegarem (moduł 15)
  signal key0_sync : std_logic_vector(1 downto 0) := "11";
  signal rst       : std_logic;
  signal blink_1hz : std_logic;
  signal blink_4hz : std_logic;
begin
  process (MAX10_CLK1_50)
  begin
    if rising_edge(MAX10_CLK1_50) then
      key0_sync <= key0_sync(0) & KEY(0);
    end if;
  end process;

  rst <= not key0_sync(1);

  u_blink_1hz : entity work.blink
    generic map (CLK_HZ => 50_000_000, BLINK_HZ => 1)
    port map (clk => MAX10_CLK1_50, rst => rst, led => blink_1hz);

  u_blink_4hz : entity work.blink
    generic map (CLK_HZ => 50_000_000, BLINK_HZ => 4)
    port map (clk => MAX10_CLK1_50, rst => rst, led => blink_4hz);

  -- '1' = świeci w naszej logice, '0' = świeci na płytce
  LED <= not ("000000" & blink_4hz & blink_1hz);
end architecture rtl;
