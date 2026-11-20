-- Bufor poślizgowy (skid buffer) AXI4-Stream (21.01): pełna przepustowość, wszystkie wyjścia z przerzutników,
-- także s_ready. Gdy wyjście stoi (m_valid and not m_ready), przyjęte słowo trafia do bufora.
library ieee;
use ieee.std_logic_1164.all;

entity axis_skid is
  generic (W : positive := 8);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    s_data  : in  std_logic_vector(W - 1 downto 0);
    s_last  : in  std_logic;
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(W - 1 downto 0);
    m_last  : out std_logic;
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity axis_skid;

architecture rtl of axis_skid is
  signal bufor : std_logic_vector(W downto 0);
  signal wyj   : std_logic_vector(W downto 0);
  signal pelny, mv : std_logic := '0';
begin
  s_ready <= not pelny;
  m_valid <= mv;
  m_last  <= wyj(W);
  m_data  <= wyj(W - 1 downto 0);

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        mv    <= '0';
        pelny <= '0';
      elsif mv = '0' or m_ready = '1' then                  -- rejestr wyjściowy wolny albo właśnie oddany
        if pelny = '1' then
          wyj   <= bufor;
          mv    <= '1';
          pelny <= '0';
        else
          wyj <= s_last & s_data;
          mv  <= s_valid;
        end if;
      elsif s_valid = '1' and pelny = '0' then              -- wyjście stoi, s_ready = '1': słowo do bufora
        bufor <= s_last & s_data;
        pelny <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
