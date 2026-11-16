-- Linia opóźniająca: dout = wartość din sprzed DEPTH taktów z ce = '1'.
-- Bez resetu i bez odczytu pośrednich odczepów — syntezator może ją zbudować w pamięci RAM.
library ieee;
use ieee.std_logic_1164.all;

entity delay_line is
  generic (
    W     : positive := 8;
    DEPTH : positive := 16                           -- co najmniej 2
  );
  port (
    clk  : in  std_logic;
    ce   : in  std_logic;
    din  : in  std_logic_vector(W - 1 downto 0);
    dout : out std_logic_vector(W - 1 downto 0)
  );
end entity delay_line;

architecture rtl of delay_line is
  type sr_t is array (0 to DEPTH - 1) of std_logic_vector(W - 1 downto 0);
  signal sr : sr_t;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if ce = '1' then
        sr <= din & sr(0 to DEPTH - 2);              -- przesunięcie całej tablicy o jedną pozycję
      end if;
    end if;
  end process;

  dout <= sr(DEPTH - 1);
end architecture rtl;
