-- Kolejka FIFO synchroniczna z odczytem "z wyprzedzeniem" (rd_data = najstarszy element, gdy empty = '0').
-- Zapis: wr_en and not full; odczyt (zdjęcie elementu): rd_en and not empty; oba w jednym takcie dozwolone.
-- Wskaźniki o jeden bit szersze niż adres: równe - pusta; różne tylko najstarszym bitem - pełna.
-- Właściwości formalne - w wersji SystemVerilog (fifo_sync.sv, blok `ifdef FORMAL`).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_sync is
  generic (
    W  : positive := 8;
    AW : positive := 3                                    -- głębokość 2**AW
  );
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    wr_en   : in  std_logic;
    wr_data : in  std_logic_vector(W - 1 downto 0);
    full    : out std_logic;
    rd_en   : in  std_logic;
    rd_data : out std_logic_vector(W - 1 downto 0);
    empty   : out std_logic;
    count   : out unsigned(AW downto 0)
  );
end entity fifo_sync;

architecture rtl of fifo_sync is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem            : mem_t;
  signal wr_ptr, rd_ptr : unsigned(AW downto 0) := (others => '0');
  signal full_i, empty_i : std_logic;
  signal do_wr, do_rd   : std_logic;
begin
  empty_i <= '1' when wr_ptr = rd_ptr else '0';
  full_i  <= '1' when wr_ptr(AW - 1 downto 0) = rd_ptr(AW - 1 downto 0) and wr_ptr(AW) /= rd_ptr(AW) else '0';
  do_wr   <= wr_en and not full_i;
  do_rd   <= rd_en and not empty_i;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
      else
        if do_wr = '1' then
          wr_ptr <= wr_ptr + 1;
        end if;
        if do_rd = '1' then
          rd_ptr <= rd_ptr + 1;
        end if;
      end if;
      if do_wr = '1' then
        mem(to_integer(wr_ptr(AW - 1 downto 0))) <= wr_data;
      end if;
    end if;
  end process;

  rd_data <= mem(to_integer(rd_ptr(AW - 1 downto 0)));
  count   <= wr_ptr - rd_ptr;
  empty   <= empty_i;
  full    <= full_i;
end architecture rtl;
