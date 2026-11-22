-- Zadanie 11: skid buffer — stopień valid/ready z rejestrowanym s_ready i pełną przepustowością.
library ieee;
use ieee.std_logic_1164.all;

entity skid_buffer is
  generic (W : positive := 8);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    s_valid : in  std_logic;
    s_ready : out std_logic;
    s_data  : in  std_logic_vector(W - 1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic;
    m_data  : out std_logic_vector(W - 1 downto 0)
  );
end entity;

architecture rtl of skid_buffer is
  signal skid_v : std_logic := '0';
  signal skid_d : std_logic_vector(W - 1 downto 0) := (others => '0');
  signal o_v    : std_logic := '0';
  signal o_d    : std_logic_vector(W - 1 downto 0) := (others => '0');
begin
  s_ready <= not skid_v;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        o_v    <= '0';
        skid_v <= '0';
      elsif m_ready = '1' or o_v = '0' then
        if skid_v = '1' then
          o_d    <= skid_d;
          o_v    <= '1';
          skid_v <= '0';
        else
          o_d <= s_data;
          o_v <= s_valid;
        end if;
      elsif s_valid = '1' and skid_v = '0' then
        skid_d <= s_data;
        skid_v <= '1';
      end if;
    end if;
  end process;

  m_valid <= o_v;
  m_data  <= o_d;
end architecture;
