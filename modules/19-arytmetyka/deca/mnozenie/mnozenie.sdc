# Ograniczenia projektu "mnozenie" (moduł 19): jeden zegar 50 MHz. Raport f_max (make raporty) pokazuje,
# z jakim zapasem działają mnożarki — dla porównania wariantów zmień w deca_top parametry LAT lub H.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
