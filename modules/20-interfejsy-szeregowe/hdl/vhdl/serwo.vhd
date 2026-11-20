-- Sterownik serwomechanizmu (20.04): impuls co 20 ms, szerokość 1000 + pozycja·1000/255 µs
-- (≈ 1000 + (pozycja·1004) >> 8), pozycja pobierana na początku okresu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serwo is
  generic (CLK_HZ : positive := 50_000_000);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    pozycja : in  std_logic_vector(7 downto 0);
    impuls  : out std_logic := '0'
  );
end entity serwo;

architecture rtl of serwo is
  constant TAKTY_US : positive := CLK_HZ / 1_000_000;                -- takty na mikrosekundę
  signal dziel   : natural range 0 to TAKTY_US - 1 := 0;
  signal mikro   : natural range 0 to 19_999 := 0;
  signal szer : natural range 0 to 2047 := 1500;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        dziel     <= 0;
        mikro     <= 0;
        impuls <= '0';
      else
        if dziel = TAKTY_US - 1 then
          dziel <= 0;
          if mikro = 19_999 then
            mikro   <= 0;
            szer <= 1000 + (to_integer(unsigned(pozycja)) * 1004) / 256;
          else
            mikro <= mikro + 1;
          end if;
        else
          dziel <= dziel + 1;
        end if;
        impuls <= '1' when mikro < szer else '0';
      end if;
    end if;
  end process;
end architecture rtl;
