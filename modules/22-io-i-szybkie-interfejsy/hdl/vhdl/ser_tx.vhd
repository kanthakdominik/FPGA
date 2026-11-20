-- Serializator N:1 (22.03): słowo pobierane co N taktów zegara bitowego, wysyłane od najstarszego bitu.
library ieee;
use ieee.std_logic_1164.all;

entity ser_tx is
  generic (N : positive := 8);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    slowo   : in  std_logic_vector(N - 1 downto 0);
    pobierz : out std_logic := '0';
    q       : out std_logic
  );
end entity ser_tx;

architecture rtl of ser_tx is
  signal sr   : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal licz : natural range 0 to N - 1 := 0;
begin
  q <= sr(N - 1);
  process (clk)
  begin
    if rising_edge(clk) then
      pobierz <= '0';
      if rst = '1' then
        licz <= 0;
        sr   <= (others => '0');
      else
        if licz = N - 1 then
          licz    <= 0;
          sr      <= slowo;
          pobierz <= '1';
        else
          licz <= licz + 1;
          sr   <= sr(N - 2 downto 0) & '0';
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
