# Ograniczenia projektu "obraz" (moduł 31, 31.05): 50 MHz na wejściu PLL, zegar piksela 25 MHz.
# Dane do ADV7513 wychodzą z rejestrów w blokach I/O (FAST_OUTPUT_REGISTER) na zboczu narastającym zegara
# piksela, a HDMI_TX_CLK to ten zegar odwrócony (rejestr DDR) — ADV7513 próbkuje w połowie bitu, z zapasem
# ok. 20 ns minus przekos ścieżek; dlatego wyjścia wideo nie mają tu set_output_delay (rachunek w 24.02).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_pll_clocks
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*] HDMI_TX_INT HDMI_I2C_SDA HDMI_I2C_SCL}]
set_false_path -to   [get_ports {LED[*] HDMI_I2C_SCL HDMI_I2C_SDA}]
set_false_path -to   [get_ports {HDMI_TX_D[*] HDMI_TX_DE HDMI_TX_HS HDMI_TX_VS HDMI_TX_CLK}]
