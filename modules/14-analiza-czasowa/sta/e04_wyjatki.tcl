# 14.04 — ścieżka wielotaktowa dzielnika, false path i max_delay. Zegar 8 ns.
source wspolne.tcl
wczytaj
create_clock -name clk -period 8 [get_ports clk]
set a_r [rejestry u_dziel.a_r]
set q_r [concat [rejestry u_dziel.q] [rejestry u_dziel.r]]

sciezka bez_mcp_setup max -from $a_r -to $q_r
sciezka bez_mcp_hold  min -from $a_r -to $q_r

set_multicycle_path -setup 4 -from $a_r -to $q_r
sciezka mcp4_setup max -from $a_r -to $q_r
sciezka mcp4_hold  min -from $a_r -to $q_r

set_multicycle_path -hold 3 -from $a_r -to $q_r
sciezka mcp43_setup max -from $a_r -to $q_r
sciezka mcp43_hold  min -from $a_r -to $q_r

# false path: wejście start traktowane jako asynchroniczne — ścieżki znikają z analizy
set_input_delay -clock clk 1.0 [get_ports start]
sciezka start_przed max -from [get_ports start]
set_false_path -from [get_ports start]
sciezka start_po max -from [get_ports start]

# max_delay: wymaganie 1,5 ns na ścieżkę z wejścia b do rejestru b_r (zamiast okresu zegara)
set_input_delay -clock clk 0.0 [get_ports b*]
sciezka b_okres max -from [get_ports b*]
set_max_delay 1.5 -from [get_ports b*]
sciezka b_max_delay max -from [get_ports b*]
