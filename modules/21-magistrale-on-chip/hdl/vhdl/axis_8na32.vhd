-- Konwerter szerokości AXI4-Stream 8 -> 32 bity (21.01): pierwszy bajt w bitach 7:0, TKEEP - ważne bajty,
-- TLAST w środku słowa kończy słowo niepełne.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_8na32 is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    s_data  : in  std_logic_vector(7 downto 0);
    s_last  : in  std_logic;
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(31 downto 0);
    m_keep  : out std_logic_vector(3 downto 0);
    m_last  : out std_logic;
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity axis_8na32;

architecture rtl of axis_8na32 is
  signal zb      : std_logic_vector(31 downto 0) := (others => '0');
  signal zk      : std_logic_vector(3 downto 0) := (others => '0');
  signal i       : unsigned(1 downto 0) := "00";
  signal mv, rdy : std_logic := '0';
begin
  rdy     <= not mv or m_ready;                             -- przyjmuj, gdy wyjście może przyjąć słowo
  s_ready <= rdy;
  m_valid <= mv;

  process (clk)
    variable nd : std_logic_vector(31 downto 0);
    variable nk : std_logic_vector(3 downto 0);
  begin
    if rising_edge(clk) then
      nd := zb;
      nk := zk;
      nd(to_integer(i) * 8 + 7 downto to_integer(i) * 8) := s_data;
      nk(to_integer(i)) := '1';
      if rst = '1' then
        mv <= '0';
        i  <= "00";
        zb <= (others => '0');
        zk <= (others => '0');
      else
        if mv = '1' and m_ready = '1' then mv <= '0'; end if;
        if s_valid = '1' and rdy = '1' then
          if i = 3 or s_last = '1' then                     -- słowo pełne albo koniec pakietu
            m_data <= nd;
            m_keep <= nk;
            m_last <= s_last;
            mv     <= '1';
            i      <= "00";
            zb     <= (others => '0');
            zk     <= (others => '0');
          else
            zb <= nd;
            zk <= nk;
            i  <= i + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
