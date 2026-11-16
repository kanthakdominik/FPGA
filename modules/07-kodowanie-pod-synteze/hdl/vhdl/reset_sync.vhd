-- Synchronizator resetu: ustawienie asynchroniczne (od razu), zdjęcie synchroniczne (po STAGES taktach).
library ieee;
use ieee.std_logic_1164.all;

entity reset_sync is
  generic (
    STAGES : positive := 2                           -- co najmniej 2
  );
  port (
    clk    : in  std_logic;
    arst_n : in  std_logic;                          -- reset zewnętrzny, asynchroniczny, aktywny niski
    rst    : out std_logic                           -- reset dla logiki, aktywny wysoki
  );
end entity reset_sync;

architecture rtl of reset_sync is
  signal sync : std_logic_vector(STAGES - 1 downto 0) := (others => '0');  -- start w resecie
begin
  process (clk, arst_n)
  begin
    if arst_n = '0' then
      sync <= (others => '0');
    elsif rising_edge(clk) then
      sync <= sync(STAGES - 2 downto 0) & '1';
    end if;
  end process;

  rst <= not sync(STAGES - 1);
end architecture rtl;
