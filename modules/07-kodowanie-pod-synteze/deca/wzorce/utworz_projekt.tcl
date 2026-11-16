# Tworzy projekt Quartusa "wzorce" dla płytki DECA (moduł 07): stoper BCD i „oddychająca” fala na diodach.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile wzorce
#   quartus_pgm -c 1 -m jtag -o "p;output_files/wzorce.sof"
# albo: make, make sram, make czas (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt wzorce $tu {reset_sync tick_gen bcd_counter sine_rom delay_line} {MAX10_CLK1_50 przyciski przelaczniki diody}
