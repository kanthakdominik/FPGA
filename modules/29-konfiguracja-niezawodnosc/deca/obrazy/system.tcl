# Skrypt qsys-script (29.02): system_dual = źródło zegara 50 MHz + rdzeń Dual Configuration (altera_dual_boot)
# z eksportowanym interfejsem Avalon-MM, którym steruje moduł aktualizacja w logice użytkownika.
#   qsys-script --script=system.tcl
#   qsys-generate system_dual.qsys --synthesis=VERILOG
# Porty w module nadrzędnym: clk_clk, reset_reset_n, dual_boot_avalon_{address,read,writedata,write,readdata}.
# Nazwy interfejsów rdzenia (clk, nreset, avalon) według wersji 18–24; przy błędzie sprawdź je w GUI
# (Platform Designer -> IP Catalog -> Dual Configuration).
package require -exact qsys 16.1

create_system system_dual
set_project_property DEVICE_FAMILY "MAX 10"
set_project_property DEVICE 10M50DAF484C6GES

add_instance zegar clock_source
set_instance_parameter_value zegar clockFrequency 50000000
set_instance_parameter_value zegar clockFrequencyKnown true
set_instance_parameter_value zegar resetSynchronousEdges DEASSERT

add_instance dual_boot altera_dual_boot
add_connection zegar.clk dual_boot.clk
add_connection zegar.clk_reset dual_boot.nreset

add_interface clk clock sink
set_interface_property clk EXPORT_OF zegar.clk_in
add_interface reset reset sink
set_interface_property reset EXPORT_OF zegar.clk_in_reset
add_interface dual_boot_avalon avalon slave
set_interface_property dual_boot_avalon EXPORT_OF dual_boot.avalon

save_system system_dual.qsys
