-- ALU rdzeni RV32I (27.07): op = bit 30 instrukcji (SUB/SRA/SRAI) & funct3; przesunięcia o b(4 downto 0).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rv_alu is
  port (
    a, b : in  std_logic_vector(31 downto 0);
    op   : in  std_logic_vector(3 downto 0);
    y    : out std_logic_vector(31 downto 0)
  );
end entity rv_alu;

architecture rtl of rv_alu is
begin
  process (all)
    variable sh : natural range 0 to 31;
  begin
    sh := to_integer(unsigned(b(4 downto 0)));
    case op(2 downto 0) is
      when "000" =>
        if op(3) = '1' then y <= std_logic_vector(unsigned(a) - unsigned(b));
        else y <= std_logic_vector(unsigned(a) + unsigned(b)); end if;
      when "001" => y <= std_logic_vector(shift_left(unsigned(a), sh));
      when "010" =>
        y <= (others => '0');
        if signed(a) < signed(b) then y(0) <= '1'; end if;
      when "011" =>
        y <= (others => '0');
        if unsigned(a) < unsigned(b) then y(0) <= '1'; end if;
      when "100" => y <= a xor b;
      when "101" =>
        if op(3) = '1' then y <= std_logic_vector(shift_right(signed(a), sh));
        else y <= std_logic_vector(shift_right(unsigned(a), sh)); end if;
      when "110" => y <= a or b;
      when others => y <= a and b;
    end case;
  end process;
end architecture rtl;
