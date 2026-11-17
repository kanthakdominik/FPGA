# 14.01 — setup i hold dla ścieżek rejestr–rejestr. Zegar 8 ns (125 MHz), idealny.
source wspolne.tcl
wczytaj
create_clock -name clk -period 8 [get_ports clk]

set a_r [rejestry u_dziel.a_r]
set q_r [rejestry u_dziel.q]
# najdłuższa ścieżka projektu: dzielnik a_r -> q (bez ograniczenia wielotaktowego)
sciezka dzielnik_setup max -from $a_r -to $q_r
# najkrótsza ścieżka projektu (hold)
sciezka najkrotsza_hold min
# ścieżki w nadajniku SPI: krótkie, zapas dodatni
sciezka spi_setup max -from [get_cells u_spi.*_reg] -to [get_cells u_spi.*_reg]
report_tns
report_wns
