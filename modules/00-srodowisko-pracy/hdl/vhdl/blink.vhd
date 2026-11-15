-- Migająca dioda: dzielnik częstotliwości z licznikiem.
-- Wyjście led zmienia stan co CLK_HZ / (2 * BLINK_HZ) taktów zegara.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blink is
  generic (
    CLK_HZ   : positive := 50_000_000;  -- częstotliwość zegara wejściowego
    BLINK_HZ : positive := 1            -- częstotliwość migania diody
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;                -- reset synchroniczny, aktywny wysoki
    led : out std_logic
  );
end entity blink;

architecture rtl of blink is
  constant HALF : positive := CLK_HZ / (2 * BLINK_HZ);  -- takty na pół okresu
  signal cnt_q : natural range 0 to HALF - 1 := 0;
  signal led_q : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt_q <= 0;
        led_q <= '0';
      elsif cnt_q = HALF - 1 then
        cnt_q <= 0;
        led_q <= not led_q;
      else
        cnt_q <= cnt_q + 1;
      end if;
    end if;
  end process;

  led <= led_q;
end architecture rtl;
