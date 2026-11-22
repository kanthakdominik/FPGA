-- Zadanie 3: dzielnik zegara przez 3 z wypełnieniem 50 % — p (zbocze narastające, 1 okres z 3) OR n (p opóźnione
-- o pół okresu na zboczu opadającym). Wyjście nie jest zegarem dla logiki w FPGA (do tego PLL lub zezwolenie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div3 is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    clk_out : out std_logic
  );
end entity;

architecture rtl of clk_div3 is
  signal cnt : unsigned(1 downto 0) := "00";
  signal p   : std_logic := '0';
  signal n   : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= "00";
        p   <= '0';
      else
        if cnt = 2 then cnt <= "00"; else cnt <= cnt + 1; end if;
        if cnt = 2 then p <= '1'; else p <= '0'; end if;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if falling_edge(clk) then
      if rst = '1' then n <= '0'; else n <= p; end if;
    end if;
  end process;

  clk_out <= p or n;
end architecture;
