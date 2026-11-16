-- Sygnały a zmienne w procesie taktowanym.
-- Łańcuch przypisań sygnałów tworzy dwa rejestry, ten sam łańcuch zmiennych — połączenia bez rejestrów.
library ieee;
use ieee.std_logic_1164.all;

entity sig_var_demo is
  port (
    clk   : in  std_logic;
    d     : in  std_logic;
    q_sig : out std_logic;                   -- d opóźnione o 2 takty
    q_var : out std_logic                    -- d opóźnione o 1 takt
  );
end entity sig_var_demo;

architecture rtl of sig_var_demo is
  signal s1, s2 : std_logic := '0';
begin
  process (clk)
    variable v1, v2 : std_logic;
  begin
    if rising_edge(clk) then
      -- sygnały: prawa strona to wartości sprzed zbocza -> s1 i s2 to dwa kolejne rejestry
      s1 <= d;
      s2 <= s1;
      -- zmienne: v1 przyjmuje d od razu, v2 też -> to tylko połączenia, rejestrem jest q_var
      v1 := d;
      v2 := v1;
      q_var <= v2;
    end if;
  end process;

  q_sig <= s2;
end architecture rtl;
