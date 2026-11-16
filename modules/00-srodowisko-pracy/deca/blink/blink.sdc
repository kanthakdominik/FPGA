# Ograniczenia czasowe projektu blink na DECA.
# Zegar 50 MHz z generatora na płytce (okres 20 ns).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]

# Niepewność zegara (jitter, PLL) wyliczona przez Quartus.
derive_clock_uncertainty

# Przyciski i diody są asynchroniczne względem zegara i powolne — nie analizujemy ich czasów.
# Przycisk przechodzi przez synchronizator w deca_top, diody zmieniają stan kilka razy na sekundę.
set_false_path -from [get_ports {KEY[*]}]
set_false_path -to   [get_ports {LED[*]}]
