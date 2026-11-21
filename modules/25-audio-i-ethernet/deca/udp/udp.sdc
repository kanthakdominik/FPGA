# Ograniczenia projektu "udp" (moduł 25): 50 MHz (MDIO, diody), TX_CLK i RX_CLK z PHY po 25 MHz (MII 100 Mb/s).
# Trzy domeny niezależne. MII (IEEE 802.3 kl. 22.3): PHY próbkuje TXD/TX_EN przy narastającym TX_CLK z
# t_SU ≥ 10 ns i t_H ≥ 0; RXD/RX_DV/RX_ER zmieniają się 10–30 ns po narastającym RX_CLK.
create_clock -name clk50  -period 20.000 [get_ports {MAX10_CLK1_50}]
create_clock -name tx_clk -period 40.000 [get_ports {NET_TX_CLK}]
create_clock -name rx_clk -period 40.000 [get_ports {NET_RX_CLK}]
derive_clock_uncertainty
set_clock_groups -asynchronous -group [get_clocks {clk50}] -group [get_clocks {tx_clk}] -group [get_clocks {rx_clk}]

set_output_delay -clock tx_clk -max 10.0 [get_ports {NET_TXD[*] NET_TX_EN}]
set_output_delay -clock tx_clk -min  0.0 [get_ports {NET_TXD[*] NET_TX_EN}]
set_input_delay  -clock rx_clk -max 30.0 [get_ports {NET_RXD[*] NET_RX_DV NET_RX_ER}]
set_input_delay  -clock rx_clk -min 10.0 [get_ports {NET_RXD[*] NET_RX_DV NET_RX_ER}]

set_false_path -from [get_ports {KEY[*] SW[*] NET_MDIO NET_COL NET_CRS}]
set_false_path -to   [get_ports {LED[*] NET_MDC NET_MDIO NET_RESET_n NET_PCF_EN}]
