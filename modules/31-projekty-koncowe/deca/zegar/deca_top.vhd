-- DECA — projekt 1 (31.01), VHDL: zegar i stoper sterowane komendami UART 115 200 b/s 8N1.
--   GPIO0_D(0) - TX, GPIO0_D(1) - RX (przejściówka USB-UART 3,3 V). LED(6:0) - sekundy zegara w BCD
--   (SW(0) = 1: sekundy stopera), LED(7) - stoper biegnie, KEY(0) - reset. Diody świecą stanem niskim.
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    SW            : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);
    GPIO0_D       : inout std_logic_vector(1 downto 0)
  );
end entity deca_top;

architecture rtl of deca_top is
  signal clk, rst, tx_s, bieg : std_logic;
  signal rs, s_sw : std_logic_vector(1 downto 0) := "00";
  signal czas, stoper : std_logic_vector(23 downto 0);
  signal sek : std_logic_vector(6 downto 0);
begin
  clk <= MAX10_CLK1_50;
  process (clk, KEY)
  begin
    if KEY(0) = '0' then
      rs <= "00";
    elsif rising_edge(clk) then
      rs <= rs(0) & '1';
    end if;
  end process;
  rst <= not rs(1);
  process (clk) begin if rising_edge(clk) then s_sw <= s_sw(0) & SW(0); end if; end process;

  u_p : entity work.projekt_zegar generic map (CLK_HZ => 50_000_000, BAUD => 115_200, CS_DZIEL => 500_000)
    port map (clk => clk, rst => rst, rx => GPIO0_D(1), tx => tx_s, czas => czas, stoper => stoper,
              biegnie => bieg, pominieto => open, blad_ramki => open);
  GPIO0_D(0) <= tx_s;
  GPIO0_D(1) <= 'Z';
  sek <= stoper(14 downto 8) when s_sw(1) = '1' else czas(6 downto 0);
  LED <= not (bieg & sek);
end architecture rtl;
