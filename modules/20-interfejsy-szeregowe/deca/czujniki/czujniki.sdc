# Ograniczenia projektu "czujniki" (moduł 20): zegar 50 MHz. Interfejsy czujników są wolne (SPI 1–2 MHz,
# I²C 100 kHz) i taktowane z logiki, wejścia przechodzą przez synchronizatory — ścieżki I/O wyłączone z analizy.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*] G_SENSOR_* TEMP_* RH_TEMP_* GPIO0_D[*]}]
set_false_path -to   [get_ports {LED[*] G_SENSOR_* TEMP_* RH_TEMP_* GPIO0_D[*]}]
