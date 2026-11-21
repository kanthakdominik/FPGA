-- Przetwornik sigma-delta pierwszego rzędu (26.03): próbka 16 bitów ze znakiem -> strumień bitów o gęstości
-- jedynek (x + 32768)/65536. Za filtrem RC na wyjściu cyfrowym daje napięcie proporcjonalne do próbki.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sd_dac is
  port (
    clk, rst : in  std_logic;
    x        : in  signed(15 downto 0);
    q        : out std_logic := '0'
  );
end entity sd_dac;

architecture rtl of sd_dac is
  signal acc : unsigned(16 downto 0) := (others => '0');
begin
  process (clk)
    variable u : unsigned(16 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        acc <= (others => '0'); q <= '0';
      else
        u   := "0" & (not x(15)) & unsigned(x(14 downto 0));       -- kod z przesunięciem o 2^15
        acc <= ('0' & acc(15 downto 0)) + u;
        q   <= acc(16);
      end if;
    end if;
  end process;
end architecture rtl;
