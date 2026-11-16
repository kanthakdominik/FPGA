-- Średnia krocząca z 4 ostatnich próbek ze znakiem: y = floor((x + x1 + x2 + x3) / 4).
-- Wyjście rejestrowane: po zboczu z in_valid = '1' — y z nową próbką i out_valid = '1'; bez in_valid y się nie zmienia.
-- Układ testowy dla całego modułu 09 (testbench podstawowy, z modelem, z wektorów z pliku).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mavg4 is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    x         : in  signed(7 downto 0);
    out_valid : out std_logic;
    y         : out signed(7 downto 0)
  );
end entity mavg4;

architecture rtl of mavg4 is
  signal x1, x2, x3 : signed(7 downto 0);                      -- trzy poprzednie próbki
  signal sum        : signed(9 downto 0);
begin
  sum <= resize(x, 10) + resize(x1, 10) + resize(x2, 10) + resize(x3, 10);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        x1        <= (others => '0');
        x2        <= (others => '0');
        x3        <= (others => '0');
        out_valid <= '0';
        y         <= (others => '0');
      else
        out_valid <= in_valid;
        if in_valid = '1' then
          y  <= resize(shift_right(sum, 2), 8);                -- shift_right na signed = arytmetyczne
          x3 <= x2;
          x2 <= x1;
          x1 <= x;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
