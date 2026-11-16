-- Zatrzask D: przezroczysty przy en = '1', pamięta przy en = '0'.
-- Celowy przykład — w kodzie FPGA zatrzaski są zwykle błędem (temat 07.03).
library ieee;
use ieee.std_logic_1164.all;

entity d_latch is
  port (
    en : in  std_logic;
    d  : in  std_logic;
    q  : out std_logic
  );
end entity d_latch;

architecture rtl of d_latch is
begin
  process (all)
  begin
    if en = '1' then
      q <= d;
    end if;                                  -- brak else: q pamięta — powstaje zatrzask
  end process;
end architecture rtl;
