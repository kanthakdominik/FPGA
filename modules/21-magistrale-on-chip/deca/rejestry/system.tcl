# Skrypt qsys-script (21.06): system_rej = źródło zegara + JTAG to Avalon Master Bridge + avmm_rejestry
# pod adresem 0x0000. To samo da się wyklikać w Platform Designer (README.md); skrypt jest powtarzalny
# i mieści się w repozytorium jako tekst.
#   qsys-script --script=system.tcl --search-path="./,$"
#   qsys-generate system_rej.qsys --synthesis=VERILOG --search-path="./,$"
package require -exact qsys 16.1

create_system system_rej
set_project_property DEVICE_FAMILY "MAX 10"
set_project_property DEVICE 10M50DAF484C6GES

add_instance zegar clock_source
set_instance_parameter_value zegar clockFrequency 50000000
set_instance_parameter_value zegar clockFrequencyKnown true
set_instance_parameter_value zegar resetSynchronousEdges DEASSERT

add_instance jtag altera_jtag_avalon_master
add_instance rej avmm_rejestry

add_connection zegar.clk       jtag.clk
add_connection zegar.clk       rej.zegar
add_connection zegar.clk_reset jtag.clk_reset
add_connection zegar.clk_reset rej.reset
add_connection jtag.master     rej.s0
set_connection_parameter_value jtag.master/rej.s0 baseAddress 0x0000

add_interface clk clock sink
set_interface_property clk EXPORT_OF zegar.clk_in
add_interface reset reset sink
set_interface_property reset EXPORT_OF zegar.clk_in_reset
add_interface uklad conduit end
set_interface_property uklad EXPORT_OF rej.uklad

save_system system_rej.qsys
