-- Master I2S (25.01): BCLK = clk/4, WCLK = clk/256 (64 bity na ramkę), format I2S (MSB jeden takt BCLK po zmianie
-- WCLK; WCLK = '0' — lewy). dout zmienia się przy opadającym BCLK, din próbkowany po narastającym.
-- Impuls ramka: przyjęto tx_l/tx_p i podano rx_l/rx_p z poprzedniej ramki.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2s_master is
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    tx_l  : in  std_logic_vector(23 downto 0);
    tx_p  : in  std_logic_vector(23 downto 0);
    rx_l  : out std_logic_vector(23 downto 0) := (others => '0');
    rx_p  : out std_logic_vector(23 downto 0) := (others => '0');
    ramka : out std_logic := '0';
    bclk  : out std_logic := '0';
    wclk  : out std_logic := '0';
    dout  : out std_logic := '0';
    din   : in  std_logic
  );
end entity i2s_master;

architecture rtl of i2s_master is
  signal cnt : unsigned(7 downto 0) := (others => '0');
  signal wy, we : std_logic_vector(63 downto 0) := (others => '0');
begin
  process (clk)
    variable n : natural range 0 to 63;
  begin
    if rising_edge(clk) then
      n := to_integer(cnt(7 downto 2));
      if rst = '1' then
        cnt <= (others => '0'); wy <= (others => '0'); we <= (others => '0');
        rx_l <= (others => '0'); rx_p <= (others => '0'); ramka <= '0';
        bclk <= '0'; wclk <= '0'; dout <= '0';
      else
        cnt   <= cnt + 1;
        ramka <= '0';
        if cnt = 255 then
          wy    <= tx_l & x"00" & tx_p & x"00";
          rx_l  <= we(63 downto 40);
          rx_p  <= we(31 downto 8);
          ramka <= '1';
        end if;
        bclk <= cnt(1);
        wclk <= cnt(7);
        if cnt(1 downto 0) = "00" then
          if n = 0 then dout <= '0'; else dout <= wy(63 - (n - 1)); end if;
        end if;
        if cnt(1 downto 0) = "11" and n /= 0 then
          we(63 - (n - 1)) <= din;
        end if;
      end if;
    end if;
  end process;
end architecture rtl;
