-- Moduł nadrzędny dla płytki DECA — VHDL. Czysta logika kombinacyjna, bez zegara.
-- a = SW(1 downto 0) (przełącznik w dół = '0'), b = odwrócone KEY(1 downto 0) (wciśnięty przycisk = '1').
-- LED(3 downto 0) — dekoder a, LED(5 downto 4) — suma a + b, LED(6) — przeniesienie, LED(7) — a > b.
-- Diody DECA świecą przy stanie niskim, więc wyjścia są odwrócone.
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    SW  : in  std_logic_vector(1 downto 0);   -- przełączniki, w dół = '0'
    KEY : in  std_logic_vector(1 downto 0);   -- przyciski, wciśnięty = '0'
    LED : out std_logic_vector(7 downto 0)    -- diody, '0' = świeci
  );
end entity deca_top;

architecture rtl of deca_top is
  signal a, b     : std_logic_vector(1 downto 0);
  signal dec      : std_logic_vector(3 downto 0);
  signal sum      : std_logic_vector(1 downto 0);
  signal cout, gt : std_logic;
begin
  a <= SW;
  b <= not KEY;                               -- wciśnięty przycisk = jedynka logiczna

  u_dec : entity work.decoder
    generic map (N => 2)
    port map (a => a, y => dec);

  u_add : entity work.rca_adder
    generic map (W => 2)
    port map (a => a, b => b, cin => '0', s => sum, cout => cout);

  u_cmp : entity work.comparator
    generic map (W => 2)
    port map (a => a, b => b, eq => open, lt => open, gt => gt);

  -- '1' = świeci w naszej logice, '0' = świeci na płytce
  LED <= not (gt & cout & sum & dec);
end architecture rtl;
