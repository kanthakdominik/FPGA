-- Maksimum z N liczb bez znaku — pętla: łańcuch N - 1 porównań, głębokość logiki rośnie liniowo z N.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity max_chain is
  generic (
    N : positive := 8;
    W : positive := 8
  );
  port (
    x : in  std_logic_vector(N * W - 1 downto 0);   -- element i: x((i + 1) * W - 1 downto i * W)
    y : out std_logic_vector(W - 1 downto 0)
  );
end entity max_chain;

architecture rtl of max_chain is
begin
  process (all)
    variable m, e : unsigned(W - 1 downto 0);
  begin
    m := unsigned(x(W - 1 downto 0));
    for i in 1 to N - 1 loop                         -- każdy obieg pętli = kolejny komparator i multiplekser
      e := unsigned(x((i + 1) * W - 1 downto i * W));
      if e > m then
        m := e;
      end if;
    end loop;
    y <= std_logic_vector(m);
  end process;
end architecture rtl;
