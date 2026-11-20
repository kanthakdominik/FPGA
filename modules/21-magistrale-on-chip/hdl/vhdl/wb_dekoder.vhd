-- Dekoder adresu Wishbone (21.04): master -> slave 0 (adres słowa 0x000-0x1FF, pamięć), slave 1 (0x200-0x20F,
-- rejestry), reszta - ERR z dekodera. Obaj slave'y w trybie potokowym z odpowiedzią po 1 takcie.
library ieee;
use ieee.std_logic_1164.all;

entity wb_dekoder is
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    m_cyc    : in  std_logic;
    m_stb    : in  std_logic;
    m_we     : in  std_logic;
    m_adr    : in  std_logic_vector(9 downto 0);
    m_dat_i  : in  std_logic_vector(31 downto 0);
    m_sel    : in  std_logic_vector(3 downto 0);
    m_dat_o  : out std_logic_vector(31 downto 0);
    m_ack    : out std_logic;
    m_err    : out std_logic;
    m_stall  : out std_logic;
    s0_stb   : out std_logic;
    s0_adr   : out std_logic_vector(8 downto 0);
    s0_dat_o : in  std_logic_vector(31 downto 0);
    s0_ack   : in  std_logic;
    s0_stall : in  std_logic;
    s1_stb   : out std_logic;
    s1_adr   : out std_logic_vector(3 downto 0);
    s1_dat_o : in  std_logic_vector(31 downto 0);
    s1_ack   : in  std_logic;
    s1_err   : in  std_logic;
    s1_stall : in  std_logic;
    s_cyc    : out std_logic;
    s_we     : out std_logic;
    s_dat_i  : out std_logic_vector(31 downto 0);
    s_sel    : out std_logic_vector(3 downto 0)
  );
end entity wb_dekoder;

architecture rtl of wb_dekoder is
  signal w0, w1, err_d : std_logic := '0';
begin
  w0 <= not m_adr(9);
  w1 <= '1' when m_adr(9 downto 4) = "100000" else '0';

  s_cyc   <= m_cyc;
  s_we    <= m_we;
  s_dat_i <= m_dat_i;
  s_sel   <= m_sel;
  s0_stb  <= m_stb and w0;
  s1_stb  <= m_stb and w1;
  s0_adr  <= m_adr(8 downto 0);
  s1_adr  <= m_adr(3 downto 0);
  m_stall <= s0_stall when w0 = '1' else s1_stall when w1 = '1' else '0';
  m_ack   <= s0_ack or s1_ack;
  m_err   <= s1_err or err_d;
  m_dat_o <= s1_dat_o when s1_ack = '1' else s0_dat_o;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' or m_cyc = '0' then
        err_d <= '0';
      else
        err_d <= m_stb and not w0 and not w1;              -- brak slave'a pod adresem
      end if;
    end if;
  end process;
end architecture rtl;
