-- Rejestr potokowy strumienia valid/ready z buforem „skid”: wszystkie wyjścia z rejestrów, jedno słowo na takt.
library ieee;
use ieee.std_logic_1164.all;

entity skid_buffer is
  generic (W : positive := 8);
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    s_data  : in  std_logic_vector(W - 1 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(W - 1 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity skid_buffer;

architecture rtl of skid_buffer is
  signal main_data, skid_data   : std_logic_vector(W - 1 downto 0);
  signal main_valid, skid_valid : std_logic := '0';
begin
  s_ready <= not skid_valid;
  m_valid <= main_valid;
  m_data  <= main_data;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        main_valid <= '0';
        skid_valid <= '0';
      elsif m_ready = '1' or main_valid = '0' then
        if skid_valid = '1' then
          main_data  <= skid_data;
          main_valid <= '1';
          skid_valid <= '0';
        else
          main_data  <= s_data;
          main_valid <= s_valid;
        end if;
      elsif s_valid = '1' and skid_valid = '0' then
        skid_data  <= s_data;
        skid_valid <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
