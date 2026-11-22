-- Zadanie 9: nadajnik UART 8N1; ramka {stop, dane, start} w rejestrze przesuwnym, bit = CLK_HZ / BAUD taktów.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
  generic (
    CLK_HZ : positive := 50_000_000;
    BAUD   : positive := 115_200
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    start : in  std_logic;
    data  : in  std_logic_vector(7 downto 0);
    ready : out std_logic;
    tx    : out std_logic
  );
end entity;

architecture rtl of uart_tx is
  constant DIV : positive := CLK_HZ / BAUD;
  signal sh    : std_logic_vector(9 downto 0) := (others => '1');
  signal nbit  : natural range 0 to 9 := 0;
  signal cnt   : natural range 0 to DIV - 1 := 0;
  signal busy  : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        sh <= (others => '1'); nbit <= 0; cnt <= 0; busy <= '0';
      elsif busy = '0' then
        if start = '1' then
          sh   <= '1' & data & '0';
          nbit <= 0;
          cnt  <= 0;
          busy <= '1';
        end if;
      elsif cnt = DIV - 1 then
        cnt <= 0;
        sh  <= '1' & sh(9 downto 1);
        if nbit = 9 then busy <= '0'; else nbit <= nbit + 1; end if;
      else
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  tx    <= sh(0);
  ready <= not busy;
end architecture;
