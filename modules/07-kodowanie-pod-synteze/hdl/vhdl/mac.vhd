-- Mnożenie z akumulacją (MAC) liczb ze znakiem, potok 3-stopniowy:
-- rejestry wejść -> rejestr iloczynu -> akumulator. first = '1' zaczyna nową sumę od tej próbki.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mac is
  generic (
    W     : positive := 9;                           -- 9 bitów = połowa bloku mnożarki MAX 10
    ACC_W : positive := 24
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    first     : in  std_logic;
    a         : in  signed(W - 1 downto 0);
    b         : in  signed(W - 1 downto 0);
    acc       : out signed(ACC_W - 1 downto 0);
    acc_valid : out std_logic
  );
end entity mac;

architecture rtl of mac is
  signal a_r, b_r    : signed(W - 1 downto 0);
  signal p_r         : signed(2 * W - 1 downto 0);
  signal acc_r       : signed(ACC_W - 1 downto 0);
  signal v1, v2, v3  : std_logic := '0';
  signal f1, f2      : std_logic;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      a_r <= a;                                      -- rejestry danych bez resetu — mogą trafić do bloku mnożarki
      b_r <= b;
      f1  <= first;
      p_r <= a_r * b_r;                              -- numeric_std: szerokość iloczynu = suma szerokości
      f2  <= f1;
      if v2 = '1' then
        if f2 = '1' then
          acc_r <= resize(p_r, ACC_W);
        else
          acc_r <= acc_r + resize(p_r, ACC_W);
        end if;
      end if;
      if rst = '1' then
        v1 <= '0';
        v2 <= '0';
        v3 <= '0';
      else
        v1 <= in_valid;
        v2 <= v1;
        v3 <= v2;
      end if;
    end if;
  end process;

  acc       <= acc_r;
  acc_valid <= v3;
end architecture rtl;
