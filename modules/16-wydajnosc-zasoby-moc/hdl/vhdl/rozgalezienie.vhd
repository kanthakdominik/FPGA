-- Duży fanout (16.03): rejestr przesuwny N bitów z zezwoleniem en_r (fanout N). NDUP > 1: en_r
-- zduplikowany NDUP razy, każda kopia steruje N/NDUP przerzutnikami; dont_merge (Quartus) chroni kopie
-- przed scaleniem - Yosys scala je mimo atrybutów (eksperymenty.py e3).
library ieee;
use ieee.std_logic_1164.all;

entity rozgalezienie is
  generic (
    N    : positive := 256;
    NDUP : positive := 1
  );
  port (
    clk : in  std_logic;
    en  : in  std_logic;
    d   : in  std_logic;
    q   : out std_logic
  );
end entity rozgalezienie;

architecture rtl of rozgalezienie is
  constant GRUPA : positive := N / NDUP;
  signal en_r : std_logic_vector(NDUP - 1 downto 0) := (others => '0');
  signal sr   : std_logic_vector(N - 1 downto 0)    := (others => '0');

  attribute keep : boolean;
  attribute keep of en_r : signal is true;
  attribute dont_merge : boolean;
  attribute dont_merge of en_r : signal is true;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      en_r <= (others => en);
      for i in 0 to N - 1 loop
        if en_r(i / GRUPA) = '1' then
          if i = 0 then
            sr(0) <= d;
          else
            sr(i) <= sr(i - 1);
          end if;
        end if;
      end loop;
    end if;
  end process;
  q <= sr(N - 1);
end architecture rtl;
