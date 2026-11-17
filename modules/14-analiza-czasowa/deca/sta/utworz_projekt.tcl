# Tworzy projekt Quartusa "sta" dla płytki DECA (moduł 14): PLL 100 MHz, dzielnik ze ścieżką wielotaktową
# i SPI 25 MHz na złączu P8 z ograniczeniami w sta.sdc.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile sta
#   quartus_pgm -c 1 -m jtag -o "p;output_files/sta.sof"
# albo: make, make sram, make czas, make raporty (zob. plytka-deca/deca.mk i Makefile)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt sta $tu {dzielnik_mc spi_master} {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1] GPIO0_D[2] GPIO0_D[3]}
