-- Zadanie 8: asynchroniczna kolejka FIFO ze wskaźnikami w kodzie Graya (Cummings, SNUG 2002); do drugiej domeny
-- przechodzi tylko wskaźnik Graya przez dwa przerzutniki. Odczyt rejestrowany. AW >= 2.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_fifo is
  generic (
    W  : positive := 8;
    AW : positive := 4
  );
  port (
    wr_clk  : in  std_logic;
    wr_rst  : in  std_logic;
    wr_en   : in  std_logic;
    wr_data : in  std_logic_vector(W - 1 downto 0);
    full    : out std_logic;
    rd_clk  : in  std_logic;
    rd_rst  : in  std_logic;
    rd_en   : in  std_logic;
    rd_data : out std_logic_vector(W - 1 downto 0);
    empty   : out std_logic
  );
end entity;

architecture rtl of async_fifo is
  type mem_t is array (0 to 2 ** AW - 1) of std_logic_vector(W - 1 downto 0);
  signal mem : mem_t;

  function to_gray(b : unsigned) return unsigned is
  begin
    return b xor shift_right(b, 1);
  end function;

  signal wbin, wgray, rgray_w1, rgray_w2 : unsigned(AW downto 0) := (others => '0');
  signal rbin, rgray, wgray_r1, wgray_r2 : unsigned(AW downto 0) := (others => '0');
  signal full_i, empty_i                 : std_logic;
  signal q                               : std_logic_vector(W - 1 downto 0) := (others => '0');
begin
  -- domena zapisu
  full_i <= '1' when wgray = (not rgray_w2(AW downto AW - 1)) & rgray_w2(AW - 2 downto 0) else '0';

  process (wr_clk)
  begin
    if rising_edge(wr_clk) then
      if wr_en = '1' and full_i = '0' then
        mem(to_integer(wbin(AW - 1 downto 0))) <= wr_data;
      end if;
      if wr_rst = '1' then
        wbin <= (others => '0'); wgray <= (others => '0');
        rgray_w1 <= (others => '0'); rgray_w2 <= (others => '0');
      else
        rgray_w1 <= rgray;
        rgray_w2 <= rgray_w1;
        if wr_en = '1' and full_i = '0' then
          wbin  <= wbin + 1;
          wgray <= to_gray(wbin + 1);
        end if;
      end if;
    end if;
  end process;

  -- domena odczytu
  empty_i <= '1' when rgray = wgray_r2 else '0';

  process (rd_clk)
  begin
    if rising_edge(rd_clk) then
      if rd_en = '1' and empty_i = '0' then
        q <= mem(to_integer(rbin(AW - 1 downto 0)));
      end if;
      if rd_rst = '1' then
        rbin <= (others => '0'); rgray <= (others => '0');
        wgray_r1 <= (others => '0'); wgray_r2 <= (others => '0');
      else
        wgray_r1 <= wgray;
        wgray_r2 <= wgray_r1;
        if rd_en = '1' and empty_i = '0' then
          rbin  <= rbin + 1;
          rgray <= to_gray(rbin + 1);
        end if;
      end if;
    end if;
  end process;

  full    <= full_i;
  empty   <= empty_i;
  rd_data <= q;
end architecture;
