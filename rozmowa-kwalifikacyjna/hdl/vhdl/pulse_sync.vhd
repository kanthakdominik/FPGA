-- Zadanie 7: impuls z domeny A do domeny B przez przełącznik i synchronizator dwóch przerzutników.
-- Odstęp między impulsami w A musi być dłuższy niż ok. 3 takty B.
library ieee;
use ieee.std_logic_1164.all;

entity pulse_sync is
  port (
    clk_a   : in  std_logic;
    rst_a   : in  std_logic;
    pulse_a : in  std_logic;
    clk_b   : in  std_logic;
    rst_b   : in  std_logic;
    pulse_b : out std_logic
  );
end entity;

architecture rtl of pulse_sync is
  signal tog_a  : std_logic := '0';
  signal sync_b : std_logic_vector(2 downto 0) := "000";
begin
  process (clk_a)
  begin
    if rising_edge(clk_a) then
      if rst_a = '1' then
        tog_a <= '0';
      elsif pulse_a = '1' then
        tog_a <= not tog_a;
      end if;
    end if;
  end process;

  process (clk_b)
  begin
    if rising_edge(clk_b) then
      if rst_b = '1' then sync_b <= "000"; else sync_b <= sync_b(1 downto 0) & tog_a; end if;
    end if;
  end process;

  pulse_b <= sync_b(2) xor sync_b(1);
end architecture;
