-- DECA — projekt 4 (31.04), VHDL: Nios V/m z udp_dma (system_udp z Platform Designer) wysyła datagramy UDP przez
-- PHY DP83620 (MII). Opis jak w deca_top.v. Komponent system_udp wiąże Quartus; w GHDL pozostaje niepowiązany.
library ieee;
use ieee.std_logic_1164.all;

entity deca_top is
  port (
    MAX10_CLK1_50 : in    std_logic;
    KEY           : in    std_logic_vector(1 downto 0);
    LED           : out   std_logic_vector(7 downto 0);
    NET_TX_CLK    : in    std_logic;
    NET_TXD       : out   std_logic_vector(3 downto 0);
    NET_TX_EN     : out   std_logic;
    NET_RESET_n   : out   std_logic;
    NET_MDC       : out   std_logic;
    NET_MDIO      : inout std_logic;
    NET_PCF_EN    : out   std_logic
  );
end entity deca_top;

architecture rtl of deca_top is
  component system_udp
    port (
      clk_clk        : in  std_logic;
      reset_reset_n  : in  std_logic;
      tx_clk_clk     : in  std_logic;
      tx_reset_reset : in  std_logic;
      mii_txd        : out std_logic_vector(3 downto 0);
      mii_tx_en      : out std_logic
    );
  end component;
  signal clk, rst_n, tx_rst, tx_en_s, phy_ok, nadaje : std_logic;
  signal rs, trs : std_logic_vector(1 downto 0) := "00";
  signal lr : natural range 0 to 1_000_000 := 0;
  signal dl : natural range 0 to 4_194_303 := 0;
begin
  clk <= MAX10_CLK1_50;
  process (clk, KEY(0))
  begin
    if KEY(0) = '0' then rs <= "00"; elsif rising_edge(clk) then rs <= rs(0) & '1'; end if;
  end process;
  rst_n <= rs(1);
  process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then lr <= 0; elsif lr /= 1_000_000 then lr <= lr + 1; end if;
    end if;
  end process;
  phy_ok <= '1' when lr >= 500_000 else '0';
  NET_RESET_n <= phy_ok;
  NET_MDC <= '0';
  NET_MDIO <= 'Z';
  NET_PCF_EN <= '0';

  process (NET_TX_CLK, rst_n)
  begin
    if rst_n = '0' then trs <= "00"; elsif rising_edge(NET_TX_CLK) then trs <= trs(0) & '1'; end if;
  end process;
  tx_rst <= not trs(1);

  u_sys : system_udp
    port map (clk_clk => clk, reset_reset_n => rst_n, tx_clk_clk => NET_TX_CLK, tx_reset_reset => tx_rst,
              mii_txd => NET_TXD, mii_tx_en => tx_en_s);
  NET_TX_EN <= tx_en_s;

  process (NET_TX_CLK)
  begin
    if rising_edge(NET_TX_CLK) then
      if tx_en_s = '1' then dl <= 4_194_303; elsif dl /= 0 then dl <= dl - 1; end if;
    end if;
  end process;
  nadaje <= '0' when dl = 0 else '1';
  LED <= not ("000000" & nadaje & phy_ok);
end architecture rtl;
