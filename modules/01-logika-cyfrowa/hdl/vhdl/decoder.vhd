-- Dekoder N na 2**N (kod 1 z n): ustawia jedynkę na wyjściu o numerze a.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder is
  generic (N : positive := 3);
  port (
    a : in  std_logic_vector(N - 1 downto 0);
    y : out std_logic_vector(2 ** N - 1 downto 0)
  );
end entity decoder;

architecture rtl of decoder is
begin
  process (all)
  begin
    y <= (others => '0');                  -- wartość domyślna: brak zatrzasku
    y(to_integer(unsigned(a))) <= '1';
  end process;
end architecture rtl;
