# 14.03 — opóźnienia wejść i wyjść, zegar wirtualny, zegary generowane, sprawdzanie kompletności.
source wspolne.tcl
wczytaj
create_clock -name clk -period 8 [get_ports clk]
puts "### kontrola_bez_io"
check_setup -verbose
puts "### koniec"

# Zegar wirtualny: zegar układu zewnętrznego, który nie wchodzi do FPGA (ten sam okres, faza 0).
create_clock -name v_clk -period 8
set wejscia [lsearch -all -inline -not [all_inputs] [get_ports clk]]
set_input_delay  -clock v_clk -max 3.0 $wejscia
set_input_delay  -clock v_clk -min 0.5 $wejscia
set_output_delay -clock v_clk -max 2.0 [all_outputs]
set_output_delay -clock v_clk -min -0.5 [all_outputs]
puts "### kontrola_z_io"
check_setup -verbose
puts "### koniec"

sciezka wejscie_setup max -from [get_ports a*]
sciezka wejscie_hold  min -from [get_ports a*]
sciezka wyjscie_setup max -to [get_ports q*]
sciezka wyjscie_hold  min -to [get_ports q*]

# Zegar generowany w rejestrze: sclk = clk / 4
create_generated_clock -name sclk_reg -source [get_ports clk] -divide_by 4 [wyjscie_q u_spi.sclk_r]
report_clock_properties
