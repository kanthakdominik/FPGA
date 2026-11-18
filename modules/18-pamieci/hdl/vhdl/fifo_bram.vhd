-- Synchroniczna kolejka FIFO na pamięci blokowej (18.03). FWFT = false: dana takt po rd_en;
-- FWFT = true: najstarsza dana czeka na dout, gdy empty = '0' (rejestr wyjściowy pamięci jako stopień
-- wyprzedzenia, pojemność 2^AW + 1). almost_full = count >= AF, almost_empty = count <= AE.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_bram is
  generic (
    W    : positive := 8;
    AW   : positive := 4;
    FWFT : boolean  := false;
    AF   : natural  := 12;
    AE   : natural  := 2
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;
    wr_en        : in  std_logic;
    din          : in  std_logic_vector(W - 1 downto 0);
    full         : out std_logic;
    almost_full  : out std_logic;
    rd_en        : in  std_logic;
    dout         : out std_logic_vector(W - 1 downto 0);
    empty        : out std_logic;
    almost_empty : out std_logic;
    count        : out std_logic_vector(AW + 1 downto 0)
  );
end entity fifo_bram;

architecture rtl of fifo_bram is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem            : mem_t;
  signal wr_ptr, rd_ptr : unsigned(AW - 1 downto 0) := (others => '0');
  signal n_mem          : unsigned(AW downto 0) := (others => '0');
  signal valid          : std_logic := '0';
  signal mem_empty, full_i, do_wr, do_rd : std_logic;
  signal cnt            : unsigned(AW + 1 downto 0);
begin
  mem_empty <= '1' when n_mem = 0 else '0';
  full_i    <= '1' when n_mem = 2 ** AW else '0';
  do_wr     <= wr_en and not full_i;

  g_fwft : if FWFT generate
    do_rd <= (not mem_empty) and ((not valid) or rd_en);
    empty <= not valid;
    cnt   <= resize(n_mem, AW + 2) + 1 when valid = '1' else resize(n_mem, AW + 2);
    process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          valid <= '0';
        elsif do_rd = '1' then
          valid <= '1';
        elsif rd_en = '1' then
          valid <= '0';
        end if;
      end if;
    end process;
  else generate
    do_rd <= rd_en and not mem_empty;
    empty <= mem_empty;
    cnt   <= resize(n_mem, AW + 2);
  end generate;

  full         <= full_i;
  count        <= std_logic_vector(cnt);
  almost_full  <= '1' when cnt >= AF else '0';
  almost_empty <= '1' when cnt <= AE else '0';

  process (clk)
  begin
    if rising_edge(clk) then
      if do_wr = '1' then
        mem(to_integer(wr_ptr)) <= din;
      end if;
      if do_rd = '1' then
        dout <= mem(to_integer(rd_ptr));
      end if;
      if rst = '1' then
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
        n_mem  <= (others => '0');
      else
        if do_wr = '1' then
          wr_ptr <= wr_ptr + 1;
        end if;
        if do_rd = '1' then
          rd_ptr <= rd_ptr + 1;
        end if;
        if do_wr = '1' and do_rd = '0' then
          n_mem <= n_mem + 1;
        elsif do_wr = '0' and do_rd = '1' then
          n_mem <= n_mem - 1;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
