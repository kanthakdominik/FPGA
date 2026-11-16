-- Licznik dziesiętny (BCD) z DIGITS cyfr: kaskada zezwoleń, jeden zegar dla wszystkich cyfr.
-- Cyfra i liczy, gdy en = '1' i wszystkie młodsze cyfry są równe 9. carry = przepełnienie całego licznika.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bcd_counter is
  generic (
    DIGITS : positive := 3
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    bcd   : out std_logic_vector(4 * DIGITS - 1 downto 0);  -- cyfra i: bcd(4i + 3 downto 4i)
    carry : out std_logic
  );
end entity bcd_counter;

architecture rtl of bcd_counter is
  signal c : std_logic_vector(DIGITS downto 0);      -- c(i) — zezwolenie dla cyfry i
begin
  c(0) <= en;

  g_digit : for i in 0 to DIGITS - 1 generate
    signal q : unsigned(3 downto 0) := (others => '0');
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          q <= (others => '0');
        elsif c(i) = '1' then
          if q = 9 then
            q <= (others => '0');
          else
            q <= q + 1;
          end if;
        end if;
      end if;
    end process;
    c(i + 1)                     <= c(i) when q = 9 else '0';
    bcd(4 * i + 3 downto 4 * i) <= std_logic_vector(q);
  end generate g_digit;

  carry <= c(DIGITS);
end architecture rtl;
