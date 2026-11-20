# Ograniczenia projektu "io" (moduł 22): zegar 50 MHz; wyjścia i pętla przez zworę traktowane jako ścieżki
# bez ograniczeń (margines sprawdza się na płytce przełącznikiem SW[0] i licznikiem błędów, 22.02).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
set_false_path -to   [get_ports {GPIO0_D[*]}]
set_false_path -from [get_ports {GPIO0_D[6]}]
