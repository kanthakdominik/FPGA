# Ograniczenia projektu "oscyloskop" (moduł 31, 31.02): dwie domeny zegara — akwizycja 10 MHz (adc_pll
# z ADC_CLK_10) i piksel 25 MHz (altpll z MAX10_CLK1_50). Domeny są asynchroniczne: jedyne przejścia to
# przełączniki gotowy/potwierdzenie z synchronizatorami, stabilne dane zrzutu (bank, początek), wolnozmienny
# poziom wyzwalania i pamięć z dwoma zegarami — stąd grupy zegarów rozłącznych.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
create_clock -name clk10 -period 100.000 [get_ports {ADC_CLK_10}]
derive_pll_clocks
derive_clock_uncertainty
set_clock_groups -asynchronous -group [get_clocks {clk50 u_pll*}] -group [get_clocks {clk10 u_apll*}]

set_false_path -from [get_ports {KEY[*] SW[*] HDMI_TX_INT HDMI_I2C_SDA HDMI_I2C_SCL}]
set_false_path -to   [get_ports {LED[*] HDMI_I2C_SCL HDMI_I2C_SDA}]
set_false_path -to   [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS HDMI_TX_CLK}]
