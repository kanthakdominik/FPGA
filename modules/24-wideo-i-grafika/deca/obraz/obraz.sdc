# Ograniczenia projektu "obraz" (moduł 24): 50 MHz — domena pamięci i generatora, 25 MHz z PLL — domena piksela.
# Domeny traktowane jako asynchroniczne: między nimi są tylko synchronizatory bitów przełączanych i bufor linii
# w pamięci dwuzegarowej (24.04). Wyjścia wideo jak w projekcie "hdmi".
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_pll_clocks
derive_clock_uncertainty
set_clock_groups -asynchronous -group [get_clocks {clk50}] -group [get_clocks {*u_pll*}]

set_false_path -from [get_ports {KEY[*] SW[*] HDMI_TX_INT HDMI_I2C_SDA HDMI_I2C_SCL}]
set_false_path -to   [get_ports {LED[*] HDMI_I2C_SCL HDMI_I2C_SDA}]
set_false_path -to   [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS HDMI_TX_CLK}]
