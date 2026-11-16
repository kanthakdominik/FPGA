-- LFSR w postaci Galois, przesuw w prawo. Przypisania sygnałów w pętli — kolejność iteracji nie ma znaczenia.
library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
  generic (
    W    : positive         := 16;
    TAPS : std_logic_vector := x"B400";         -- x^16 + x^14 + x^13 + x^11 + 1
    SEED : std_logic_vector := x"0001"
  );
  port (
    clk : in  std_logic;
    rst : in  std_logic;                        -- synchroniczny: ładuje SEED
    en  : in  std_logic;
    q   : out std_logic_vector(W - 1 downto 0)
  );
end entity lfsr;

architecture rtl of lfsr is
  -- normalizacja generic bez ograniczeń do zakresu (W - 1 downto 0)
  constant T : std_logic_vector(W - 1 downto 0) := TAPS;
  signal   s : std_logic_vector(W - 1 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        s <= SEED;
      elsif en = '1' then
        for i in 0 to W - 2 loop
          s(i) <= s(i + 1) xor (T(i) and s(0));   -- prawa strona: wartości sprzed zbocza
        end loop;
        s(W - 1) <= T(W - 1) and s(0);
      end if;
    end if;
  end process;

  q <= s;
end architecture rtl;
