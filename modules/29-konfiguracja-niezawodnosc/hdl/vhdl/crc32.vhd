-- CRC-32 (IEEE 802.3, wielomian odbity 0xEDB88320) bajt po bajcie (29.02): zeruj — nowy obraz, we — kolejny
-- bajt, crc — wynik (po negacji). "123456789" -> 0xCBF43926.
library ieee;
use ieee.std_logic_1164.all;

entity crc32 is
  port (
    clk, zeruj, we : in  std_logic;
    bajt           : in  std_logic_vector(7 downto 0);
    crc            : out std_logic_vector(31 downto 0)
  );
end entity crc32;

architecture rtl of crc32 is
  signal r : std_logic_vector(31 downto 0) := (others => '1');

  function krok(c : std_logic_vector(31 downto 0); b : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable t : std_logic_vector(31 downto 0);
  begin
    t := c xor (x"000000" & b);
    for i in 0 to 7 loop
      if t(0) = '1' then
        t := ('0' & t(31 downto 1)) xor x"EDB88320";
      else
        t := '0' & t(31 downto 1);
      end if;
    end loop;
    return t;
  end function;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if zeruj = '1' then
        r <= (others => '1');
      elsif we = '1' then
        r <= krok(r, bajt);
      end if;
    end if;
  end process;
  crc <= not r;
end architecture rtl;
