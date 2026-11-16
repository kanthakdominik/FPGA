-- CRC-8 liczone bajt po bajcie (domyślnie wielomian 0x07, wartość początkowa 0x00).
library ieee;
use ieee.std_logic_1164.all;

entity crc8 is
  generic (POLY : std_logic_vector(7 downto 0) := x"07");
  port (
    clk  : in  std_logic;
    rst  : in  std_logic;
    en   : in  std_logic;
    data : in  std_logic_vector(7 downto 0);
    crc  : out std_logic_vector(7 downto 0)
  );
end entity crc8;

architecture rtl of crc8 is
  -- funkcja zadeklarowana w architekturze: widoczna tylko tutaj
  function crc8_byte(c, d : std_logic_vector(7 downto 0)) return std_logic_vector is
    variable r : std_logic_vector(7 downto 0);
  begin
    r := c xor d;
    for i in 0 to 7 loop
      if r(7) = '1' then
        r := (r(6 downto 0) & '0') xor POLY;
      else
        r := r(6 downto 0) & '0';
      end if;
    end loop;
    return r;
  end function;

  signal c_q : std_logic_vector(7 downto 0) := (others => '0');
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        c_q <= (others => '0');
      elsif en = '1' then
        c_q <= crc8_byte(c_q, data);
      end if;
    end if;
  end process;

  crc <= c_q;
end architecture rtl;
