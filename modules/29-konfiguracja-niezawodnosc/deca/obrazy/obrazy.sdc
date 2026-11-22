# Ograniczenia projektu "obrazy" (moduł 29, 29.02): zegar 50 MHz z oscylatora; rdzeń Dual Configuration
# taktowany tym samym zegarem (dopuszczalna częstotliwość rdzenia — dokumentacja MAX 10 Configuration User Guide).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
