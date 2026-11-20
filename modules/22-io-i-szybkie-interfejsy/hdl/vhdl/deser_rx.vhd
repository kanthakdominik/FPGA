-- Deserializator 1:N z przesunięciem granicy słowa (bitslip) (22.03).
library ieee;
use ieee.std_logic_1164.all;

entity deser_rx is
  generic (N : positive := 8);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    d       : in  std_logic;
    bitslip : in  std_logic;
    slowo   : out std_logic_vector(N - 1 downto 0);
    wazne   : out std_logic := '0'
  );
end entity deser_rx;

architecture rtl of deser_rx is
  signal sr        : std_logic_vector(N - 1 downto 0) := (others => '0');
  signal licz      : natural range 0 to N - 1 := 0;
  signal wstrzymaj : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      wazne <= '0';
      if rst = '1' then
        licz      <= 0;
        wstrzymaj <= '0';
      else
        sr <= sr(N - 2 downto 0) & d;
        if bitslip = '1' then wstrzymaj <= '1'; end if;
        if wstrzymaj = '1' then
          wstrzymaj <= '0';                                -- pominięty krok licznika: granica o bit dalej
        elsif licz = N - 1 then
          licz  <= 0;
          slowo <= sr(N - 2 downto 0) & d;
          wazne <= '1';
        else
          licz <= licz + 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
