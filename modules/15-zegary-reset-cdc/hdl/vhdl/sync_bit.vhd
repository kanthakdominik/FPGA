-- Synchronizator poziomu: STAGES przerzutników w domenie docelowej (15.03).
-- Wejście d pochodzi z innej domeny (albo z pinu) i może zmieniać się w dowolnej chwili; wyjście q jest
-- bezpieczne w domenie clk po STAGES taktach. Dla wektora W > 1 każdy bit synchronizowany osobno -
-- poprawne TYLKO, gdy w jednej chwili zmienia się co najwyżej jeden bit (kod Graya, 15.04).
-- Atrybuty: ASYNC_REG (AMD: przerzutniki obok siebie, analiza MTBF), altera_attribute (Intel).
library ieee;
use ieee.std_logic_1164.all;

entity sync_bit is
  generic (
    STAGES : positive := 2;                  -- co najmniej 2
    W      : positive := 1
  );
  port (
    clk : in  std_logic;
    d   : in  std_logic_vector(W - 1 downto 0);
    q   : out std_logic_vector(W - 1 downto 0)
  );
end entity sync_bit;

architecture rtl of sync_bit is
  type stopnie_t is array (0 to STAGES - 1) of std_logic_vector(W - 1 downto 0);
  signal sync_r : stopnie_t := (others => (others => '0'));

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of sync_r : signal is "TRUE";
  attribute altera_attribute : string;
  attribute altera_attribute of sync_r : signal is "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS";
begin
  process (clk)
  begin
    if rising_edge(clk) then
      sync_r(0) <= d;
      for k in 1 to STAGES - 1 loop
        sync_r(k) <= sync_r(k - 1);
      end loop;
    end if;
  end process;

  q <= sync_r(STAGES - 1);
end architecture rtl;
