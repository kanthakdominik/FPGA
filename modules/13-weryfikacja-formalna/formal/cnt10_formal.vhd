-- Opakowanie formalne licznika cnt10 w VHDL z właściwościami PSL (13.02). Wejścia rst i en są wolne.
-- Synteza do SymbiYosys przez wtyczkę GHDL: ghdl --std=08 -fpsl ... -e cnt10_formal
-- Właściwości zapisane w komentarzach zaczynających się od "psl" (z -fpsl GHDL je kompiluje; VHDL-2008
-- dopuszcza też zapis bez komentarza). Uwaga: każdy komentarz zaczynający się od tego słowa jest czytany jako kod.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cnt10_formal is
  port (
    clk : in std_logic;
    rst : in std_logic;
    en  : in std_logic
  );
end entity cnt10_formal;

architecture formal of cnt10_formal is
  signal q    : unsigned(3 downto 0);
  signal wrap : std_logic;
  signal init : std_logic := '1';                 -- '1' tylko w pierwszym takcie
  signal q_d  : unsigned(3 downto 0);             -- q z poprzedniego taktu
begin
  dut : entity work.cnt10
    port map (clk => clk, rst => rst, en => en, q => q, wrap => wrap);

  process (clk)
  begin
    if rising_edge(clk) then
      init <= '0';
      q_d  <= q;
    end if;
  end process;

  -- psl default clock is rising_edge(clk);

  -- psl assume_reset : assume always (init = '1' -> rst = '1');

  -- psl assert_range : assert always (init = '0' -> q <= 9);
  -- psl assert_reset : assert always {rst = '1'} |=> {q = 0};
  -- psl assert_hold  : assert always {rst = '0' and en = '0'} |=> {q = q_d};
  -- psl assert_wrap  : assert always {rst = '0' and en = '1' and q = 9} |=> {q = 0};
  -- psl assert_inc   : assert always {rst = '0' and en = '1' and q /= 9} |=> {q = q_d + 1};
  -- psl assert_out   : assert always (wrap = '1') = (en = '1' and q = 9);

  -- psl cover_wrap   : cover {init = '0' and rst = '0' and wrap = '1'};
  -- psl cover_twice  : cover {wrap = '1'; [*]; wrap = '1'};
end architecture formal;
