# Ograniczenia projektu "udp_ddr3" (moduł 31, 31.04): zegar systemu 50 MHz i zegar nadawania MII 25 MHz z PHY.
# Jedyne przejścia między domenami są w udp_dma: kolejka asynchroniczna (wskaźniki Graya) i przełączniki
# ramka/potwierdzenie z synchronizatorami — domeny asynchroniczne. Wyjścia MII: PHY próbkuje TXD/TX_EN na
# zboczu narastającym TX_CLK; MAC zmienia je na tym samym zboczu — wymagania z karty DP83620 (t_su, t_h) wpisz
# jako set_output_delay po sprawdzeniu w swojej wersji dokumentacji.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
create_clock -name tx_clk -period 40.000 [get_ports {NET_TX_CLK}]
derive_pll_clocks
derive_clock_uncertainty
set_clock_groups -asynchronous -group [get_clocks {clk50}] -group [get_clocks {tx_clk}]
set_output_delay -clock tx_clk -max 10.0 [get_ports {NET_TXD[*] NET_TX_EN}]
set_output_delay -clock tx_clk -min 0.0  [get_ports {NET_TXD[*] NET_TX_EN}]
set_false_path -from [get_ports {KEY[*]}]
set_false_path -to   [get_ports {LED[*] NET_RESET_n NET_MDC NET_MDIO NET_PCF_EN}]
