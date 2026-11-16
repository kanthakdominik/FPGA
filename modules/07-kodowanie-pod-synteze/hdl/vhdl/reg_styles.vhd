-- Trzy rejestry z tym samym wejściem: reset asynchroniczny, reset synchroniczny i bez resetu.
library ieee;
use ieee.std_logic_1164.all;

entity reg_styles is
  generic (
    W : positive := 8
  );
  port (
    clk     : in  std_logic;
    arst    : in  std_logic;                         -- asynchroniczny, aktywny wysoki
    srst    : in  std_logic;                         -- synchroniczny, aktywny wysoki
    d       : in  std_logic_vector(W - 1 downto 0);
    q_async : out std_logic_vector(W - 1 downto 0);
    q_sync  : out std_logic_vector(W - 1 downto 0);
    q_none  : out std_logic_vector(W - 1 downto 0)
  );
end entity reg_styles;

architecture rtl of reg_styles is
begin
  p_async : process (clk, arst)                      -- reset na liście wrażliwości, przed zboczem
  begin
    if arst = '1' then
      q_async <= (others => '0');
    elsif rising_edge(clk) then
      q_async <= d;
    end if;
  end process p_async;

  p_sync : process (clk)                             -- reset sprawdzany tylko na zboczu zegara
  begin
    if rising_edge(clk) then
      if srst = '1' then
        q_sync <= (others => '0');
      else
        q_sync <= d;
      end if;
    end if;
  end process p_sync;

  p_none : process (clk)                             -- rejestr danych bez resetu
  begin
    if rising_edge(clk) then
      q_none <= d;
    end if;
  end process p_none;
end architecture rtl;
