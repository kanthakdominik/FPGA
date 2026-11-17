# 14.02 — niepewność zegara (jitter), przesunięcie (skew) i narożniki procesu.
source wspolne.tcl
wczytaj
create_clock -name clk -period 8 [get_ports clk]

# ścieżka referencyjna: krótki rejestr przesuwny sh_rx[1] -> sh_rx[2]
set od [bit u_spi.sh_rx 1]
set do [bit u_spi.sh_rx 2]
sciezka ref_setup max -from $od -to $do
sciezka ref_hold  min -from $od -to $do

# niepewność: setup 0,3 ns (jitter + zapas), hold 0,1 ns
set_clock_uncertainty -setup 0.3 [get_clocks clk]
set_clock_uncertainty -hold  0.1 [get_clocks clk]
sciezka niep_setup max -from $od -to $do
sciezka niep_hold  min -from $od -to $do
set_clock_uncertainty -setup 0 [get_clocks clk]
set_clock_uncertainty -hold  0 [get_clocks clk]

# skew: zegar dochodzi do przerzutnika odbierającego 1,0 ns później niż do nadającego
set_clock_latency 1.0 [get_pins "[get_full_name [lindex $do 0]]/CK"]
sciezka skew_setup max -from $od -to $do
sciezka skew_hold  min -from $od -to $do
