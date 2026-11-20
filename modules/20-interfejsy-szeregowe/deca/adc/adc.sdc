# Ograniczenia projektu "adc" (moduł 20, 20.06): wejście 10 MHz, zegar logiki z PLL (adc_pll).
create_clock -name clk10 -period 100.000 [get_ports {ADC_CLK_10}]
derive_pll_clocks
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
