# Ograniczenia projektu "rejestry" (moduł 21): zegar 50 MHz; zegar JTAG (altera_reserved_tck) ograniczają
# pliki .sdc dołączane przez system Platform Designer.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
