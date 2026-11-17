# Ograniczenia projektu "wydajnosc" (moduł 16): jeden zegar 150 MHz z PLL.

create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
create_generated_clock -name clk_sys -source [get_pins -compatibility_mode {*u_pll*|inclk[0]}] \
    -multiply_by 3 [get_pins -compatibility_mode {*u_pll*|clk[0]}]
derive_clock_uncertainty

# Przyciski, przełączniki (za synchronizatorami) i diody: bez wymagań czasowych.
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
set_false_path -through [get_pins -compatibility_mode {*u_pll*|locked}]
