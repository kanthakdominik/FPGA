-- Tablica ćwiartki sinusa: data = round(255 * sin(pi/2 * (addr + 0.5) / 64)), addr = 0..63.
-- Zawartość liczona funkcją podczas elaboracji (math_real tylko w stałych), odczyt synchroniczny —
-- syntezator może umieścić tablicę w bloku pamięci jako ROM.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity sine_rom is
  port (
    clk  : in  std_logic;
    addr : in  std_logic_vector(5 downto 0);
    data : out std_logic_vector(7 downto 0)
  );
end entity sine_rom;

architecture rtl of sine_rom is
  type rom_t is array (0 to 63) of std_logic_vector(7 downto 0);

  function init_rom return rom_t is
    variable r : rom_t;
  begin
    for i in rom_t'range loop
      r(i) := std_logic_vector(to_unsigned(
                integer(round(255.0 * sin(MATH_PI_OVER_2 * (real(i) + 0.5) / 64.0))), 8));
    end loop;
    return r;
  end function init_rom;

  constant ROM : rom_t := init_rom;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      data <= ROM(to_integer(unsigned(addr)));
    end if;
  end process;
end architecture rtl;
