-- Asynchroniczna kolejka FIFO (15.05) - wskaźniki w kodzie Graya, architektura C. Cummingsa (SNUG 2002).
-- Zapis w domenie wr_clk, odczyt w domenie rd_clk, głębokość 2**AW, odczyt z wyprzedzeniem (rd_data ważne,
-- gdy rd_empty = '0'). Wskaźniki mają AW+1 bitów; do drugiej domeny przechodzą tylko ich wersje Graya
-- (rejestry wr_gray, rd_gray) przez synchronizatory wektorowe.
--   rd_empty: rd_gray = zsynchronizowany wr_gray            (dokładne przy odczycie, pesymistyczne przy zapisie)
--   wr_full : wr_gray = ~2 najstarsze bity zsynchr. rd_gray  (dokładne przy zapisie, pesymistyczne przy odczycie)
-- Opóźnienie flag jest zawsze "bezpieczne": kolejka może wyglądać na pełną/pustą dłużej, nigdy krócej.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_fifo is
  generic (
    W      : positive := 8;
    AW     : positive := 4;                    -- głębokość 2**AW
    STAGES : positive := 2
  );
  port (
    wr_clk   : in  std_logic;
    wr_rst   : in  std_logic;
    wr_en    : in  std_logic;
    wr_data  : in  std_logic_vector(W - 1 downto 0);
    wr_full  : out std_logic;
    rd_clk   : in  std_logic;
    rd_rst   : in  std_logic;
    rd_en    : in  std_logic;
    rd_data  : out std_logic_vector(W - 1 downto 0);
    rd_empty : out std_logic
  );
end entity async_fifo;

architecture rtl of async_fifo is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem : mem_t;

  signal wr_bin, rd_bin                 : unsigned(AW downto 0) := (others => '0');
  signal wr_gray, rd_gray               : std_logic_vector(AW downto 0) := (others => '0');
  signal rd_gray_w, wr_gray_r           : std_logic_vector(AW downto 0);   -- po synchronizacji
  signal wr_bin_n, rd_bin_n             : unsigned(AW downto 0);
  signal wr_gray_n, rd_gray_n           : std_logic_vector(AW downto 0);
  signal full_i                         : std_logic := '0';
  signal empty_i                        : std_logic := '1';
  signal do_wr, do_rd                   : std_logic;
begin
  -- ---------------- domena zapisu ----------------
  do_wr     <= wr_en and not full_i;
  wr_bin_n  <= wr_bin + 1 when do_wr = '1' else wr_bin;
  wr_gray_n <= std_logic_vector(wr_bin_n xor shift_right(wr_bin_n, 1));

  process (wr_clk)
  begin
    if rising_edge(wr_clk) then
      if do_wr = '1' then
        mem(to_integer(wr_bin(AW - 1 downto 0))) <= wr_data;
      end if;
      if wr_rst = '1' then
        wr_bin  <= (others => '0');
        wr_gray <= (others => '0');
        full_i  <= '0';
      else
        wr_bin  <= wr_bin_n;
        wr_gray <= wr_gray_n;
        -- pełna: zapis wyprzedza odczyt o całe okrążenie - w Grayu: dwa najstarsze bity odwrócone
        if wr_gray_n = (not rd_gray_w(AW downto AW - 1)) & rd_gray_w(AW - 2 downto 0) then
          full_i <= '1';
        else
          full_i <= '0';
        end if;
      end if;
    end if;
  end process;

  u_sync_rd : entity work.sync_bit
    generic map (STAGES => STAGES, W => AW + 1)
    port map (clk => wr_clk, d => rd_gray, q => rd_gray_w);

  -- ---------------- domena odczytu ----------------
  do_rd     <= rd_en and not empty_i;
  rd_bin_n  <= rd_bin + 1 when do_rd = '1' else rd_bin;
  rd_gray_n <= std_logic_vector(rd_bin_n xor shift_right(rd_bin_n, 1));

  process (rd_clk)
  begin
    if rising_edge(rd_clk) then
      if rd_rst = '1' then
        rd_bin  <= (others => '0');
        rd_gray <= (others => '0');
        empty_i <= '1';
      else
        rd_bin  <= rd_bin_n;
        rd_gray <= rd_gray_n;
        if rd_gray_n = wr_gray_r then
          empty_i <= '1';
        else
          empty_i <= '0';
        end if;
      end if;
    end if;
  end process;

  u_sync_wr : entity work.sync_bit
    generic map (STAGES => STAGES, W => AW + 1)
    port map (clk => rd_clk, d => wr_gray, q => wr_gray_r);

  rd_data  <= mem(to_integer(rd_bin(AW - 1 downto 0)));
  wr_full  <= full_i;
  rd_empty <= empty_i;
end architecture rtl;
