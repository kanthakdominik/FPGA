-- Rejestr wejściowy DDR - model behawioralny (22.02): bit próbkowany zboczem narastającym (q_h) i następnym
-- opadającym (q_l), oba wyprowadzone przy kolejnym zboczu narastającym. W układzie: ALTDDIO_IN, IDDR.
library ieee;
use ieee.std_logic_1164.all;

entity ddr_wej is
  port (
    clk : in  std_logic;
    d   : in  std_logic;
    q_h : out std_logic := '0';
    q_l : out std_logic := '0'
  );
end entity ddr_wej;

architecture beh of ddr_wej is
  signal r, f : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      r   <= d;
      q_h <= r;
      q_l <= f;
    end if;
    if falling_edge(clk) then
      f <= d;
    end if;
  end process;
end architecture beh;
