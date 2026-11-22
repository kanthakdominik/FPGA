-- Zadanie 2: licznik modulo N z zezwoleniem i wyjściem przeniesienia (do łączenia kaskadowego).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_counter is
  generic (
    N : positive := 10;
    W : positive := 4                   -- >= ceil(log2(N))
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    en    : in  std_logic;
    q     : out unsigned(W - 1 downto 0);
    carry : out std_logic
  );
end entity;

architecture rtl of mod_counter is
  signal cnt     : unsigned(W - 1 downto 0) := (others => '0');
  signal at_last : std_logic;
begin
  at_last <= '1' when cnt = N - 1 else '0';

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= (others => '0');
      elsif en = '1' then
        if at_last = '1' then cnt <= (others => '0'); else cnt <= cnt + 1; end if;
      end if;
    end if;
  end process;

  q     <= cnt;
  carry <= en and at_last;
end architecture;
