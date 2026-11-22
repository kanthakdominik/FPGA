# Tworzy projekt Quartusa "zegar" dla płytki DECA (moduł 31, 31.01): zegar i stoper sterowane komendami
# UART 115 200 b/s na złączu GPIO (GPIO0_D[0] — TX, GPIO0_D[1] — RX), przejściówka USB-UART 3,3 V.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile zegar
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt zegar $tu {uart_rx uart_tx zegar_stoper komendy projekt_zegar} {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1]}
