# Ograniczenia projektu "zegar" (moduł 31, 31.01): zegar 50 MHz; linie UART i przyciski są asynchroniczne
# (synchronizatory w logice), więc wyłączone z analizy.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*] GPIO0_D[*]}]
set_false_path -to   [get_ports {LED[*] GPIO0_D[*]}]
