-- Timer odliczający w dół z automatycznym przeładowaniem — styl dwóch procesów (kombinacyjny + taktowany).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity down_timer is
  generic (W : positive := 16);
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    en     : in  std_logic;
    load   : in  std_logic;
    period : in  std_logic_vector(W - 1 downto 0);
    count  : out std_logic_vector(W - 1 downto 0);
    tick   : out std_logic
  );
end entity down_timer;

architecture rtl of down_timer is
  signal cnt, cnt_next   : unsigned(W - 1 downto 0) := (others => '0');
  signal tck, tck_next   : std_logic := '0';
begin
  process (all)
  begin
    cnt_next <= cnt;
    tck_next <= '0';
    if load = '1' then
      cnt_next <= unsigned(period);
    elsif en = '1' then
      if cnt = 0 then
        cnt_next <= unsigned(period);
        tck_next <= '1';
      else
        cnt_next <= cnt - 1;
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        cnt <= (others => '0');
        tck <= '0';
      else
        cnt <= cnt_next;
        tck <= tck_next;
      end if;
    end if;
  end process;

  count <= std_logic_vector(cnt);
  tick  <= tck;
end architecture rtl;
