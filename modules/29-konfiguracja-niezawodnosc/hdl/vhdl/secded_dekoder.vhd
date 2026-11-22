-- Dekoder SECDED (39,32) (29.04): błąd pojedynczy poprawiony (poprawiony = parzystość całości), podwójny wykryty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.secded_pkg.all;

entity secded_dekoder is
  port (
    c          : in  std_logic_vector(38 downto 0);
    d          : out std_logic_vector(31 downto 0);
    poprawiony : out std_logic;
    podwojny   : out std_logic
  );
end entity secded_dekoder;

architecture rtl of secded_dekoder is
begin
  process (all)
    variable s    : std_logic_vector(5 downto 0);
    variable par  : std_logic;
    variable popr : slowo_kod;
  begin
    s := syndrom(c);
    par := xor c;
    popr := c;
    if par = '1' and to_integer(unsigned(s)) <= 38 then
      popr(to_integer(unsigned(s))) := not c(to_integer(unsigned(s)));
    end if;
    d          <= dane(popr);
    poprawiony <= par;
    podwojny   <= '1' when par = '0' and s /= "000000" else '0';
  end process;
end architecture rtl;
