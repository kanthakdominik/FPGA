-- Pamięć dwuportowa prosta (18.01): zapis w domenie clk_w, odczyt synchroniczny w domenie clk_r.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sdp is
  generic (
    W  : positive := 8;
    AW : positive := 8
  );
  port (
    clk_w  : in  std_logic;
    we     : in  std_logic;
    addr_w : in  std_logic_vector(AW - 1 downto 0);
    din    : in  std_logic_vector(W - 1 downto 0);
    clk_r  : in  std_logic;
    re     : in  std_logic;
    addr_r : in  std_logic_vector(AW - 1 downto 0);
    dout   : out std_logic_vector(W - 1 downto 0)
  );
end entity ram_sdp;

architecture rtl of ram_sdp is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem : mem_t;
begin
  process (clk_w)
  begin
    if rising_edge(clk_w) then
      if we = '1' then
        mem(to_integer(unsigned(addr_w))) <= din;
      end if;
    end if;
  end process;

  process (clk_r)
  begin
    if rising_edge(clk_r) then
      if re = '1' then
        dout <= mem(to_integer(unsigned(addr_r)));
      end if;
    end if;
  end process;
end architecture rtl;
