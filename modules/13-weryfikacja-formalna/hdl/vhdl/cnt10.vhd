-- Licznik dziesiętny 0…9 z zezwoleniem — najprostszy układ do pierwszych dowodów formalnych (13.01, 13.02).
-- wrap = '1' w takcie, w którym licznik przechodzi z 9 na 0. Stany 10…15 są nieosiągalne z resetu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cnt10 is
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    en   : in  std_logic;
    q    : out unsigned(3 downto 0);
    wrap : out std_logic
  );
end entity cnt10;

architecture rtl of cnt10 is
  signal q_r : unsigned(3 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q_r <= (others => '0');
      elsif en = '1' then
        if q_r = 9 then
          q_r <= (others => '0');
        else
          q_r <= q_r + 1;
        end if;
      end if;
    end if;
  end process;

  q    <= q_r;
  wrap <= '1' when en = '1' and q_r = 9 else '0';
end architecture rtl;
