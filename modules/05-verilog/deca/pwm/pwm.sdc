# Zegar 50 MHz z oscylatora płytki.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

# Diody nie mają wymagań czasowych na poziomie nanosekund.
set_false_path -to [get_ports {LED[*]}]
