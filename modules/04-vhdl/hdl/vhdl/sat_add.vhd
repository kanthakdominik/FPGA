-- Sumator liczb ze znakiem z nasyceniem: przy przepełnieniu wynik to największa albo najmniejsza liczba.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sat_add is
  generic (W : positive := 8);
  port (
    a, b : in  std_logic_vector(W - 1 downto 0);  -- liczby U2
    y    : out std_logic_vector(W - 1 downto 0);
    sat  : out std_logic                          -- '1', gdy wynik został obcięty
  );
end entity sat_add;

architecture rtl of sat_add is
  -- największa i najmniejsza liczba U2 na W bitach: 011..1 i 100..0
  -- (agregat (W - 1 => '0', others => '1') jest niedozwolony: wybór zależny od generic obok others)
  constant MAX_VAL : signed(W - 1 downto 0) := '0' & (W - 2 downto 0 => '1');
  constant MIN_VAL : signed(W - 1 downto 0) := '1' & (W - 2 downto 0 => '0');
  signal sum       : signed(W downto 0);
begin
  -- std_logic_vector -> signed (zmiana interpretacji), resize powiela bit znaku
  sum <= resize(signed(a), W + 1) + resize(signed(b), W + 1);

  process (all)
  begin
    if sum(W) /= sum(W - 1) then             -- wynik nie mieści się w W bitach
      sat <= '1';
      if sum(W) = '1' then                   -- znak prawdziwej sumy: ujemna
        y <= std_logic_vector(MIN_VAL);
      else
        y <= std_logic_vector(MAX_VAL);
      end if;
    else
      sat <= '0';
      y   <= std_logic_vector(sum(W - 1 downto 0));
    end if;
  end process;
end architecture rtl;
