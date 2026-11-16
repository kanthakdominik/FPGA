-- Licznik modulo MODULO z zezwoleniem i resetem synchronicznym.
-- Przykład pełnej jednostki projektowej: biblioteki, entity z generic i portami, architecture.
library ieee;                                -- biblioteka IEEE ...
use ieee.std_logic_1164.all;                 -- ... i pakiet z typami std_logic

entity counter_mod is
  generic (
    MODULO : positive := 10                  -- liczba stanów: 0 .. MODULO - 1
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;                   -- synchroniczny, aktywny wysoki
    en    : in  std_logic;
    count : out natural range 0 to MODULO - 1;  -- liczba całkowita z zakresem: syntezator da clog2(MODULO) bitów
    wrap  : out std_logic                    -- '1', gdy w tym takcie licznik przejdzie z MODULO - 1 do 0
  );
end entity counter_mod;

architecture rtl of counter_mod is
  signal cnt : natural range 0 to MODULO - 1 := 0;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= 0;
      elsif en = '1' then
        if cnt = MODULO - 1 then
          cnt <= 0;
        else
          cnt <= cnt + 1;
        end if;
      end if;
    end if;
  end process;

  count <= cnt;                              -- port wyjściowy nie jest czytany wewnątrz — używamy sygnału cnt
  wrap  <= '1' when en = '1' and cnt = MODULO - 1 else '0';
end architecture rtl;
