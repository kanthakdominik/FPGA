-- Pamięć jednoportowa z odczytem synchronicznym (18.01). TRYB - wynik odczytu w takcie zapisu pod ten
-- sam adres: 0 READ_FIRST (stara zawartość), 1 WRITE_FIRST (nowa dana), 2 NO_CHANGE (wyjście bez zmian).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sp is
  generic (
    W    : positive := 8;
    AW   : positive := 8;
    TRYB : natural  := 0
  );
  port (
    clk  : in  std_logic;
    we   : in  std_logic;
    addr : in  std_logic_vector(AW - 1 downto 0);
    din  : in  std_logic_vector(W - 1 downto 0);
    dout : out std_logic_vector(W - 1 downto 0)
  );
end entity ram_sp;

architecture rtl of ram_sp is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem : mem_t;
begin
  process (clk)
    variable a : natural;
  begin
    if rising_edge(clk) then
      a := to_integer(unsigned(addr));
      if we = '1' then
        mem(a) <= din;
      end if;
      case TRYB is
        when 1 =>                                  -- WRITE_FIRST
          if we = '1' then
            dout <= din;
          else
            dout <= mem(a);
          end if;
        when 2 =>                                  -- NO_CHANGE
          if we = '0' then
            dout <= mem(a);
          end if;
        when others =>                             -- READ_FIRST
          dout <= mem(a);
      end case;
    end if;
  end process;
end architecture rtl;
