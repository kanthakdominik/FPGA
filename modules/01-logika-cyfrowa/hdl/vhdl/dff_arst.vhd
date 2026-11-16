-- Przerzutnik D z resetem asynchronicznym.
library ieee;
use ieee.std_logic_1164.all;

entity dff_arst is
  port (
    clk  : in  std_logic;
    arst : in  std_logic;                    -- asynchroniczny, aktywny wysoki
    d    : in  std_logic;
    q    : out std_logic
  );
end entity dff_arst;

architecture rtl of dff_arst is
begin
  process (clk, arst)
  begin
    if arst = '1' then                       -- działa natychmiast, bez czekania na zegar
      q <= '0';
    elsif rising_edge(clk) then
      q <= d;
    end if;
  end process;
end architecture rtl;
