-- Odczyt czujnika temperatury LM71 (20.05): SPI tryb 0, 16 bitów (14-bitowa temperatura U2,
-- 0,03125 °C/LSB, i 2 bity stanu), co OKRES taktów; SI/O używana tylko jako wejście.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temp_lm71 is
  generic (
    DIV   : positive := 25;
    OKRES : positive := 25_000_000
  );
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    sc     : out std_logic;
    sio    : in  std_logic;
    cs_n   : out std_logic;
    temp   : out std_logic_vector(13 downto 0) := (others => '0');
    temp_c : out std_logic_vector(8 downto 0);
    nowe   : out std_logic := '0'
  );
end entity temp_lm71;

architecture rtl of temp_lm71 is
  signal start, zajety, gotowe : std_logic := '0';
  signal rx   : std_logic_vector(15 downto 0);
  signal t_r  : std_logic_vector(13 downto 0) := (others => '0');
  signal licz : natural range 0 to OKRES := 0;
begin
  u_spi : entity work.spi_master
    generic map (N => 16, DIV => DIV)
    port map (clk => clk, rst => rst, cpol => '0', cpha => '0', start => start, dalej => '0',
              tx_dane => x"0000", rx_dane => rx, zajety => zajety, gotowe => gotowe, sclk => sc, mosi => open,
              miso => sio, cs_n => cs_n);

  temp   <= t_r;
  temp_c <= t_r(13 downto 5);                                  -- /32

  process (clk)
  begin
    if rising_edge(clk) then
      start <= '0';
      nowe  <= '0';
      if rst = '1' then
        licz <= 0;
      elsif licz = OKRES then
        if zajety = '0' then
          licz  <= 0;
          start <= '1';
        end if;
      else
        licz <= licz + 1;
      end if;
      if gotowe = '1' then
        t_r  <= rx(15 downto 2);
        nowe <= '1';
      end if;
    end if;
  end process;
end architecture rtl;
