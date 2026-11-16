-- Rejestr przesuwny szeregowo-równoległy (deserializator): nowy bit wchodzi na najmłodszą pozycję.
library ieee;
use ieee.std_logic_1164.all;

entity shift_sipo is
  generic (
    W : positive := 8
  );
  port (
    clk   : in  std_logic;
    shift : in  std_logic;
    sin   : in  std_logic;
    dout  : out std_logic_vector(W - 1 downto 0)
  );
end entity shift_sipo;

architecture rtl of shift_sipo is
  signal sr : std_logic_vector(W - 1 downto 0);
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if shift = '1' then
        sr <= sr(W - 2 downto 0) & sin;
      end if;
    end if;
  end process;

  dout <= sr;
end architecture rtl;
