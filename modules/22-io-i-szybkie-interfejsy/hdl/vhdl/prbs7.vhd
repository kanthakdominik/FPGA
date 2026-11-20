-- Generator PRBS7 (x^7 + x^6 + 1), N bitów na takt, bit najstarszy pierwszy (22.02, 22.03).
library ieee;
use ieee.std_logic_1164.all;

entity prbs7 is
  generic (N : positive := 2);
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    q   : out std_logic_vector(N - 1 downto 0) := (others => '0')
  );
end entity prbs7;

architecture rtl of prbs7 is
  signal s : std_logic_vector(6 downto 0) := (others => '1');
begin
  process (clk)
    variable t : std_logic_vector(6 downto 0);
    variable b : std_logic_vector(N - 1 downto 0);
  begin
    if rising_edge(clk) then
      t := s;
      for i in N - 1 downto 0 loop
        b(i) := t(6) xor t(5);
        t    := t(5 downto 0) & b(i);
      end loop;
      if rst = '1' then
        s <= (others => '1');
        q <= (others => '0');
      elsif en = '1' then
        s <= t;
        q <= b;
      end if;
    end if;
  end process;
end architecture rtl;
