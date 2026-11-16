-- Pakowanie strumienia bajtów w słowa 32-bitowe (pierwszy bajt w bitach 7..0) z handshake valid/ready
-- po obu stronach. Pełna przepustowość: bajt w każdym takcie, dopóki odbiorca słów nadąża.
-- Reguły: dane przesyłane, gdy valid = '1' i ready = '1'; m_valid i m_data nie zmieniają się, dopóki
-- słowo nie zostanie odebrane. s_ready zależy kombinacyjnie od m_ready (tylko przy czwartym bajcie).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pack4 is
  port (
    clk     : in  std_logic;
    rst     : in  std_logic;
    s_data  : in  std_logic_vector(7 downto 0);
    s_valid : in  std_logic;
    s_ready : out std_logic;
    m_data  : out std_logic_vector(31 downto 0);
    m_valid : out std_logic;
    m_ready : in  std_logic
  );
end entity pack4;

architecture rtl of pack4 is
  signal cnt     : unsigned(1 downto 0) := "00";               -- liczba bajtów zebranych w acc
  signal acc     : std_logic_vector(23 downto 0);
  signal valid_q : std_logic := '0';
  signal ready_i : std_logic;
begin
  -- rejestr wyjściowy wolny albo zwalniany w tym takcie; czwarty bajt tylko, gdy jest miejsce na słowo
  ready_i <= '1' when cnt /= 3 or valid_q = '0' or m_ready = '1' else '0';
  s_ready <= ready_i;
  m_valid <= valid_q;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt     <= "00";
        valid_q <= '0';
      else
        if valid_q = '1' and m_ready = '1' then
          valid_q <= '0';                                      -- słowo odebrane
        end if;
        if s_valid = '1' and ready_i = '1' then
          cnt <= cnt + 1;
          case to_integer(cnt) is
            when 0      => acc(7 downto 0)   <= s_data;
            when 1      => acc(15 downto 8)  <= s_data;
            when 2      => acc(23 downto 16) <= s_data;
            when others =>
              m_data  <= s_data & acc;
              valid_q <= '1';                                  -- nadpisuje zerowanie powyżej — nowe słowo
          end case;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
