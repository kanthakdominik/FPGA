-- Rejestr W-bitowy z zezwoleniem zapisu (en) i resetem synchronicznym.
library ieee;
use ieee.std_logic_1164.all;

entity register_en is
  generic (W : positive := 8);
  port (
    clk : in  std_logic;
    rst : in  std_logic;                     -- synchroniczny, aktywny wysoki
    en  : in  std_logic;
    d   : in  std_logic_vector(W - 1 downto 0);
    q   : out std_logic_vector(W - 1 downto 0)
  );
end entity register_en;

architecture rtl of register_en is
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q <= (others => '0');
      elsif en = '1' then
        q <= d;
      end if;                                -- en = '0': q pamięta poprzednią wartość
    end if;
  end process;
end architecture rtl;
