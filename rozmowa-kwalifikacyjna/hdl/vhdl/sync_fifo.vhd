-- Zadanie 6: synchroniczna kolejka FIFO 2^AW słów; wskaźniki o bit dłuższe od adresu, odczyt rejestrowany.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_fifo is
  generic (
    W  : positive := 8;
    AW : positive := 4
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    wr_en   : in  std_logic;
    wr_data : in  std_logic_vector(W - 1 downto 0);
    full    : out std_logic;
    rd_en   : in  std_logic;
    rd_data : out std_logic_vector(W - 1 downto 0);
    empty   : out std_logic
  );
end entity;

architecture rtl of sync_fifo is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem      : mem_t;
  signal wp, rp   : unsigned(AW downto 0) := (others => '0');
  signal full_i   : std_logic;
  signal empty_i  : std_logic;
  signal q        : std_logic_vector(W - 1 downto 0) := (others => '0');
begin
  empty_i <= '1' when wp = rp else '0';
  full_i  <= '1' when wp(AW) /= rp(AW) and wp(AW - 1 downto 0) = rp(AW - 1 downto 0) else '0';

  process (clk)
  begin
    if rising_edge(clk) then
      if wr_en = '1' and full_i = '0' then
        mem(to_integer(wp(AW - 1 downto 0))) <= wr_data;
      end if;
      if rd_en = '1' and empty_i = '0' then
        q <= mem(to_integer(rp(AW - 1 downto 0)));
      end if;
      if rst = '1' then
        wp <= (others => '0');
        rp <= (others => '0');
      else
        if wr_en = '1' and full_i = '0' then wp <= wp + 1; end if;
        if rd_en = '1' and empty_i = '0' then rp <= rp + 1; end if;
      end if;
    end if;
  end process;

  full    <= full_i;
  empty   <= empty_i;
  rd_data <= q;
end architecture;
