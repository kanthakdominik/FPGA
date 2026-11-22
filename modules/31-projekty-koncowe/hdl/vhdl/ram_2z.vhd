-- Pamięć dwuportowa z dwoma zegarami (31.02): zapis w domenie A, odczyt rejestrowany w domenie B.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_2z is
  generic (AW : positive := 10; DW : positive := 8);
  port (
    clk_a : in  std_logic;
    we    : in  std_logic;
    wadr  : in  unsigned(AW - 1 downto 0);
    wdane : in  std_logic_vector(DW - 1 downto 0);
    clk_b : in  std_logic;
    radr  : in  unsigned(AW - 1 downto 0);
    rdane : out std_logic_vector(DW - 1 downto 0) := (others => '0')
  );
end entity ram_2z;

architecture rtl of ram_2z is
  type pam_t is array (0 to 2 ** AW - 1) of std_logic_vector(DW - 1 downto 0);
  signal pam : pam_t := (others => (others => '0'));
begin
  process (clk_a)
  begin
    if rising_edge(clk_a) then
      if we = '1' then pam(to_integer(wadr)) <= wdane; end if;
    end if;
  end process;
  process (clk_b)
  begin
    if rising_edge(clk_b) then
      rdane <= pam(to_integer(radr));
    end if;
  end process;
end architecture rtl;
