# Tworzy projekt Quartusa "uart" dla płytki DECA (moduł 20, 20.01): echo UART 115 200 b/s na złączu GPIO
# (GPIO0_D[0] — TX, GPIO0_D[1] — RX). Przejściówka USB-UART 3,3 V albo zwora między pinami (README.md).
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile uart
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt uart $tu {uart_tx uart_rx} {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1]}
