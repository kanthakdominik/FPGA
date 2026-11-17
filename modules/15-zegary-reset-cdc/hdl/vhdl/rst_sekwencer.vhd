-- Reset dwóch domen z kolejnością zwalniania (15.06). arst_n (przycisk, brak synchronizacji PLL) ustawia
-- reset w obu domenach natychmiast i asynchronicznie. Zdjęcie: najpierw domena A (po STAGES taktach clk_a),
-- potem domena B - dopiero gdy informacja "A pracuje" dotrze do domeny B przez synchronizator
-- (np. B jest konsumentem danych z A i nie może startować wcześniej niż producent).
-- Każdy reset jest zdejmowany synchronicznie ze swoim zegarem - brak naruszeń recovery/removal.
library ieee;
use ieee.std_logic_1164.all;

entity rst_sekwencer is
  generic (
    STAGES : positive := 2
  );
  port (
    arst_n : in  std_logic;
    clk_a  : in  std_logic;
    rst_a  : out std_logic;
    clk_b  : in  std_logic;
    rst_b  : out std_logic
  );
end entity rst_sekwencer;

architecture rtl of rst_sekwencer is
  signal sync_a, sync_b : std_logic_vector(STAGES - 1 downto 0) := (others => '0');
begin
  process (clk_a, arst_n)
  begin
    if arst_n = '0' then
      sync_a <= (others => '0');
    elsif rising_edge(clk_a) then
      sync_a <= sync_a(STAGES - 2 downto 0) & '1';
    end if;
  end process;
  rst_a <= not sync_a(STAGES - 1);

  process (clk_b, arst_n)
  begin
    if arst_n = '0' then
      sync_b <= (others => '0');
    elsif rising_edge(clk_b) then
      sync_b <= sync_b(STAGES - 2 downto 0) & sync_a(STAGES - 1);
    end if;
  end process;
  rst_b <= not sync_b(STAGES - 1);
end architecture rtl;
