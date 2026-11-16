-- Suma kontrolna Internetu (RFC 1071): suma słów 16-bitowych z przeniesieniem dodawanym z powrotem.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inet_checksum is
  port (
    clk      : in  std_logic;
    clear    : in  std_logic;
    valid    : in  std_logic;
    word     : in  std_logic_vector(15 downto 0);
    sum      : out std_logic_vector(15 downto 0);
    checksum : out std_logic_vector(15 downto 0)
  );
end entity inet_checksum;

architecture rtl of inet_checksum is
  signal acc : unsigned(15 downto 0) := (others => '0');
  signal tmp : unsigned(16 downto 0);
begin
  tmp <= resize(acc, 17) + resize(unsigned(word), 17);

  process (clk)
  begin
    if rising_edge(clk) then
      if clear = '1' then
        acc <= (others => '0');
      elsif valid = '1' then
        acc <= tmp(15 downto 0) + tmp(16 downto 16);   -- przeniesienie wraca na pozycję 0
      end if;
    end if;
  end process;

  sum      <= std_logic_vector(acc);
  checksum <= not std_logic_vector(acc);
end architecture rtl;
