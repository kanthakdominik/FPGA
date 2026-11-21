# Ograniczenia projektu "dsp" (moduł 26): cała logika na zegarze 50 MHz z oscylatora, bez PLL.
# Przyciski i przełączniki są asynchroniczne (synchronizowane w logice), diody i wyjścia sigma-delta wolne
# względem zegara — bez ograniczeń wejścia/wyjścia (filtr RC i tak uśrednia tysiące taktów).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*] GPIO0_D[*]}]
