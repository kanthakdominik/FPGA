-- Dekoder rozkazów z wartościami obojętnymi (VHDL-2008: case? i operator ?=).
--   1xxx_xxxx LOAD (1), 01xx_xxxx ALU (2), 001x_xxxx BRANCH (3), 0001_xxxx MOVE (4),
--   0000_0000 NOP (0), pozostałe 0000_xxxx — ILLEGAL (7)
library ieee;
use ieee.std_logic_1164.all;

entity instr_decode is
  port (
    instr     : in  std_logic_vector(7 downto 0);
    cls       : out std_logic_vector(2 downto 0);
    is_branch : out std_logic
  );
end entity instr_decode;

architecture rtl of instr_decode is
begin
  process (all)
  begin
    case? instr is                           -- '-' w wyborach oznacza "dowolna wartość bitu"
      when "1-------" => cls <= "001";
      when "01------" => cls <= "010";
      when "001-----" => cls <= "011";
      when "0001----" => cls <= "100";
      when "00000000" => cls <= "000";
      when others     => cls <= "111";
    end case?;
  end process;

  is_branch <= instr ?= "001-----";          -- porównanie z wartościami obojętnymi, wynik typu std_ulogic
end architecture rtl;
