-- Liczba jedynek w słowie (population count) — zmienna sumuje wynik w pętli.
library ieee;
use ieee.std_logic_1164.all;

entity popcount is
  generic (W : positive := 8);
  port (
    d     : in  std_logic_vector(W - 1 downto 0);
    count : out natural range 0 to W
  );
end entity popcount;

architecture rtl of popcount is
begin
  process (all)
    variable acc : natural range 0 to W;     -- zmienna: nowa wartość widoczna od razu w następnej linii
  begin
    acc := 0;
    for i in d'range loop
      if d(i) = '1' then
        acc := acc + 1;
      end if;
    end loop;
    count <= acc;                            -- sygnał dostaje ostateczną wartość zmiennej
  end process;
end architecture rtl;
