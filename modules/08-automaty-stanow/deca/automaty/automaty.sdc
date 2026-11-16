# Zegar 50 MHz z oscylatora płytki.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty

# Przyciski i przełączniki są asynchroniczne względem zegara i przechodzą przez synchronizatory
# (dwa przerzutniki resetu dla KEY[0], debounce_fsm dla KEY[1], dwa przerzutniki dla SW) — ścieżki z tych pinów nie są analizowane.
set_false_path -from [get_ports {KEY[*] SW[*]}]

# Diody nie mają wymagań czasowych na poziomie nanosekund.
set_false_path -to [get_ports {LED[*]}]
