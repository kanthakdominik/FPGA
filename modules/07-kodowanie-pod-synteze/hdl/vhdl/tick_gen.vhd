-- Generator impulsów zezwolenia: tick = '1' przez jeden takt co DIV taktów zegara. Zamiast dzielenia zegara.
library ieee;
use ieee.std_logic_1164.all;

entity tick_gen is
  generic (
    DIV : positive := 10                             -- okres w taktach, co najmniej 2
  );
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    tick : out std_logic := '0'
  );
end entity tick_gen;

architecture rtl of tick_gen is
  signal cnt : natural range 0 to DIV - 1 := 0;      -- zakres wyznacza szerokość licznika
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt  <= 0;
        tick <= '0';
      elsif cnt = DIV - 1 then
        cnt  <= 0;
        tick <= '1';
      else
        cnt  <= cnt + 1;
        tick <= '0';
      end if;
    end if;
  end process;
end architecture rtl;
