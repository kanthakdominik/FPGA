-- Pamięć RAM prosta dwuportowa (jeden port zapisu, jeden odczytu), jeden zegar, odczyt synchroniczny.
-- Odczyt spod adresu zapisywanego w tym samym takcie daje stare dane (sygnał zmienia się po zboczu).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdp_ram is
  generic (
    W  : positive := 8;
    AW : positive := 5                               -- 2**AW słów
  );
  port (
    clk   : in  std_logic;
    we    : in  std_logic;
    waddr : in  std_logic_vector(AW - 1 downto 0);
    wdata : in  std_logic_vector(W - 1 downto 0);
    raddr : in  std_logic_vector(AW - 1 downto 0);
    rdata : out std_logic_vector(W - 1 downto 0)
  );
end entity sdp_ram;

architecture rtl of sdp_ram is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem : mem_t;
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(unsigned(waddr))) <= wdata;
      end if;
      rdata <= mem(to_integer(unsigned(raddr)));     -- rejestr na wyjściu — warunek użycia bloku M9K
    end if;
  end process;
end architecture rtl;
