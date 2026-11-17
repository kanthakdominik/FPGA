-- "Bicie serca" (17.01): wyjście zmienia stan co POLOKRES taktów - pierwszy test każdego projektu
-- na płytce (zegar, konfiguracja, reset, pin diody).
library ieee;
use ieee.std_logic_1164.all;

entity bicie_serca is
  generic (
    POLOKRES : positive := 25_000_000
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    led : out std_logic
  );
end entity bicie_serca;

architecture rtl of bicie_serca is
  signal cnt   : natural range 0 to POLOKRES - 1 := 0;
  signal led_r : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt   <= 0;
        led_r <= '0';
      elsif cnt = POLOKRES - 1 then
        cnt   <= 0;
        led_r <= not led_r;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;
  led <= led_r;
end architecture rtl;
