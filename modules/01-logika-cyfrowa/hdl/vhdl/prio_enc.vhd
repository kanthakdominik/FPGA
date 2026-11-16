-- Enkoder priorytetowy: numer najstarszego ustawionego bitu wejścia; valid = '1', gdy jakikolwiek bit jest ustawiony.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

entity prio_enc is
  generic (N : positive := 8);
  port (
    a     : in  std_logic_vector(N - 1 downto 0);
    y     : out std_logic_vector(clog2(N) - 1 downto 0);
    valid : out std_logic
  );
end entity prio_enc;

architecture rtl of prio_enc is
begin
  process (all)
  begin
    y     <= (others => '0');
    valid <= '0';
    -- pętla od najmłodszego bitu: ostatnie trafienie (najstarszy bit) wygrywa
    for i in 0 to N - 1 loop
      if a(i) = '1' then
        y     <= std_logic_vector(to_unsigned(i, y'length));
        valid <= '1';
      end if;
    end loop;
  end process;
end architecture rtl;
