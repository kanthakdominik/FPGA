# Ograniczenia projektu "rv" (moduł 27, 27.07): cały SoC na zegarze 50 MHz z oscylatora, bez PLL.
# Przyciski i przełączniki asynchroniczne (synchronizowane w logice), diody wolne — bez ograniczeń we/wy.
# Ścieżka krytyczna rdzenia: EX (przekazywanie -> ALU -> porównanie -> nowy adres instrukcji -> pamięć M9K).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
