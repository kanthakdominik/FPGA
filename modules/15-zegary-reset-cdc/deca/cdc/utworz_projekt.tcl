# Tworzy projekt Quartusa "cdc" dla płytki DECA (moduł 15): dwie domeny zegarowe (50 MHz i 10 MHz),
# asynchroniczne FIFO, synchronizator impulsu, handshake i sekwencer resetu.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile cdc
#   quartus_pgm -c 1 -m jtag -o "p;output_files/cdc.sof"
# albo: make, make sram, make czas, make raporty (zob. plytka-deca/deca.mk i Makefile)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt cdc $tu {sync_bit sync_pulse cdc_handshake async_fifo rst_sekwencer} {MAX10_CLK1_50 ADC_CLK_10 przyciski przelaczniki diody}
