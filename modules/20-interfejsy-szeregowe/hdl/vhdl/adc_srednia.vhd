-- Uśrednianie z decymacją (20.06): suma 2^K próbek, wynik = suma >> K co 2^K próbek.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_srednia is
  generic (
    W : positive := 12;
    K : positive := 6
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    wazne     : in  std_logic;
    dane      : in  std_logic_vector(W - 1 downto 0);
    wyj_wazne : out std_logic := '0';
    srednia   : out std_logic_vector(W - 1 downto 0) := (others => '0')
  );
end entity adc_srednia;

architecture rtl of adc_srednia is
  signal suma : unsigned(W + K - 1 downto 0) := (others => '0');
  signal licz : unsigned(K - 1 downto 0) := (others => '0');
begin
  process (clk)
    variable nowa : unsigned(W + K - 1 downto 0);
  begin
    if rising_edge(clk) then
      wyj_wazne <= '0';
      nowa := suma + unsigned(dane);
      if rst = '1' then
        suma <= (others => '0');
        licz <= (others => '0');
      elsif wazne = '1' then
        licz <= licz + 1;
        if licz = 2 ** K - 1 then                              -- 2^K-ta próbka
          srednia   <= std_logic_vector(nowa(W + K - 1 downto K));
          wyj_wazne <= '1';
          suma      <= (others => '0');
        else
          suma <= nowa;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
