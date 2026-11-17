# 14.06 — SPI: zegar przesyłany (generowany na rejestrze i na porcie), wyjścia MOSI/CS_N i wejście MISO.
# Zegar systemowy 8 ns, sclk = clk / 4 (DIV = 2). Urządzenie: t_su = t_h = 5 ns, t_co = 2…10 ns, płytka 0,2…0,5 ns.
source wspolne.tcl
wczytaj
create_clock -name clk -period 8 [get_ports clk]
# Zegar na porcie sclk: clk podzielony przez 4 w rejestrze sclk_r; opóźnienie ścieżki zegara przez
# przerzutnik i bufor wyjściowy jest liczone (set_propagated_clock), więc MISO "wraca" z tym opóźnieniem.
create_generated_clock -name sclk_pin -source [get_ports clk] -divide_by 4 [get_ports sclk]
set_propagated_clock [all_clocks]

set_output_delay -clock sclk_pin -max [expr {5.0 + 0.5}] [get_ports {mosi cs_n}]
set_output_delay -clock sclk_pin -min [expr {0.2 - 5.0}] [get_ports {mosi cs_n}]
set_input_delay  -clock sclk_pin -clock_fall -max [expr {10.0 + 2 * 0.5}] [get_ports miso]
set_input_delay  -clock sclk_pin -clock_fall -min [expr {2.0 + 2 * 0.2}] [get_ports miso]

sciezka mosi_bez_setup max -to [get_ports mosi]
sciezka mosi_bez_hold  min -to [get_ports mosi]
sciezka miso_bez_setup max -from [get_ports miso]
sciezka miso_bez_hold  min -from [get_ports miso]

set_multicycle_path -setup -start 2 -from [get_clocks clk] -to [get_clocks sclk_pin]
set_multicycle_path -hold  -start 3 -from [get_clocks clk] -to [get_clocks sclk_pin]
set_multicycle_path -setup -end 2 -from [get_clocks sclk_pin] -to [get_clocks clk]
set_multicycle_path -hold  -end 3 -from [get_clocks sclk_pin] -to [get_clocks clk]

sciezka mosi_mcp_setup max -to [get_ports mosi]
sciezka mosi_mcp_hold  min -to [get_ports mosi]
sciezka miso_mcp_setup max -from [get_ports miso]
sciezka miso_mcp_hold  min -from [get_ports miso]
