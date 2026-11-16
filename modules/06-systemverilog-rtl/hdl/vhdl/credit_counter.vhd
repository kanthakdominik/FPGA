-- Licznik kredytów kontroli przepływu z asercjami w procesie (synteza je pomija).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity credit_counter is
  generic (MAX : positive := 8);
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    take     : in  std_logic;
    give     : in  std_logic;
    credits  : out natural range 0 to MAX;
    can_take : out std_logic
  );
end entity credit_counter;

architecture rtl of credit_counter is
  signal c : natural range 0 to MAX := MAX;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        c <= MAX;
      else
        -- reguły protokołu: nie bierz bez kredytu, nie oddawaj ponad MAX
        assert not (take = '1' and c = 0)
          report "credit_counter: take bez dostepnego kredytu" severity error;
        assert not (give = '1' and take = '0' and c = MAX)
          report "credit_counter: give ponad MAX" severity error;

        if take = '1' and give = '0' then
          c <= c - 1;
        elsif give = '1' and take = '0' then
          c <= c + 1;
        end if;
      end if;
    end if;
  end process;

  credits  <= c;
  can_take <= '1' when c /= 0 else '0';
end architecture rtl;
