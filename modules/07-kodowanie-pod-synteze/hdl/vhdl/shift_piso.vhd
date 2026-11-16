-- Rejestr przesuwny równoległo-szeregowy (serializator): wpis równoległy, wyjście od najstarszego bitu.
library ieee;
use ieee.std_logic_1164.all;

entity shift_piso is
  generic (
    W : positive := 8
  );
  port (
    clk   : in  std_logic;
    load  : in  std_logic;                           -- wpis din (ma pierwszeństwo przed shift)
    shift : in  std_logic;
    din   : in  std_logic_vector(W - 1 downto 0);
    sout  : out std_logic
  );
end entity shift_piso;

architecture rtl of shift_piso is
  signal sr : std_logic_vector(W - 1 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if load = '1' then
        sr <= din;
      elsif shift = '1' then
        sr <= sr(W - 2 downto 0) & '0';
      end if;
    end if;
  end process;

  sout <= sr(W - 1);
end architecture rtl;
