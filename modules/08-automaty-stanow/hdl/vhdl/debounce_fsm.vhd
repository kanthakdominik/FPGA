-- Eliminacja drgań styków jako automat: synchronizator 2 przerzutników, cztery stany i licznik.
-- Nowy poziom jest przyjmowany, gdy wejście po synchronizacji ma go przez N + 1 kolejnych taktów.
-- rise / fall — impulsy 1-taktowe przy zmianie poziomu po filtracji; raw — wejście po synchronizacji (bez filtra).
library ieee;
use ieee.std_logic_1164.all;

entity debounce_fsm is
  generic (
    N : positive := 8                                          -- takty stabilności, co najmniej 2
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    btn   : in  std_logic;                                     -- wejście asynchroniczne, '1' = wciśnięty
    raw   : out std_logic;
    level : out std_logic;
    rise  : out std_logic := '0';
    fall  : out std_logic := '0'
  );
end entity debounce_fsm;

architecture rtl of debounce_fsm is
  type state_t is (ST_LOW, ST_WAIT_HIGH, ST_HIGH, ST_WAIT_LOW);
  signal s1, s2 : std_logic := '0';                            -- synchronizator
  signal state  : state_t   := ST_LOW;
  signal cnt    : natural range 0 to N - 1 := 0;
begin
  p_sync : process (clk)
  begin
    if rising_edge(clk) then
      s1 <= btn;
      s2 <= s1;
    end if;
  end process p_sync;

  p_fsm : process (clk)
  begin
    if rising_edge(clk) then
      rise <= '0';
      fall <= '0';
      if rst = '1' then
        state <= ST_LOW;
        cnt   <= 0;
      else
        case state is
          when ST_LOW =>
            if s2 = '1' then
              state <= ST_WAIT_HIGH;
              cnt   <= 0;
            end if;
          when ST_WAIT_HIGH =>
            if s2 = '0' then
              state <= ST_LOW;                                 -- drganie — powrót
            elsif cnt = N - 1 then
              state <= ST_HIGH;
              rise  <= '1';
            else
              cnt <= cnt + 1;
            end if;
          when ST_HIGH =>
            if s2 = '0' then
              state <= ST_WAIT_LOW;
              cnt   <= 0;
            end if;
          when ST_WAIT_LOW =>
            if s2 = '1' then
              state <= ST_HIGH;
            elsif cnt = N - 1 then
              state <= ST_LOW;
              fall  <= '1';
            else
              cnt <= cnt + 1;
            end if;
        end case;
      end if;
    end if;
  end process p_fsm;

  raw   <= s2;
  level <= '1' when state = ST_HIGH or state = ST_WAIT_LOW else '0';
end architecture rtl;
