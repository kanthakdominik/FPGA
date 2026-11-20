# Ograniczenia projektu "naped" (moduł 20, 20.04): zegar 50 MHz; wejścia enkodera i przełączniki przez
# synchronizatory, wyjścia PWM/serwa bez wymagań względem zegara zewnętrznego.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*] GPIO0_D[*]}]
set_false_path -to   [get_ports {LED[*] GPIO0_D[*]}]
