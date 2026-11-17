-- Iloczyn skalarny czterech par liczb 8-bitowych bez znaku - wersja równoległa (16.02):
-- cztery mnożarki i drzewo sumatorów, jeden wynik na takt, opóźnienie 2 takty.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iloczyn_rown is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    a         : in  std_logic_vector(31 downto 0);
    b         : in  std_logic_vector(31 downto 0);
    out_valid : out std_logic;
    y         : out std_logic_vector(17 downto 0)
  );
end entity iloczyn_rown;

architecture rtl of iloczyn_rown is
  type iloczyny_t is array (0 to 3) of unsigned(15 downto 0);
  signal a_r, b_r : std_logic_vector(31 downto 0);
  signal p        : iloczyny_t;
  signal v_r, v_o : std_logic := '0';
begin
  g_p : for i in 0 to 3 generate
    p(i) <= unsigned(a_r(8 * i + 7 downto 8 * i)) * unsigned(b_r(8 * i + 7 downto 8 * i));
  end generate;

  process (clk)
  begin
    if rising_edge(clk) then
      a_r <= a;
      b_r <= b;
      y   <= std_logic_vector((resize(p(0), 18) + resize(p(1), 18)) + (resize(p(2), 18) + resize(p(3), 18)));
      if rst = '1' then
        v_r <= '0';
        v_o <= '0';
      else
        v_r <= in_valid;
        v_o <= v_r;
      end if;
    end if;
  end process;
  out_valid <= v_o;
end architecture rtl;
