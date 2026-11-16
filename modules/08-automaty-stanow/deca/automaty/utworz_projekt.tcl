# Tworzy projekt Quartusa "automaty" dla płytki DECA (moduł 08): procesor sekwencyjny liczący ciąg Fibonacciego i licznik naciśnięć przycisku.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile automaty
#   quartus_pgm -c 1 -m jtag -o "p;output_files/automaty.sof"
# albo: make, make sram, make czas (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt automaty $tu {debounce_fsm tiny_cpu} {MAX10_CLK1_50 przyciski przelaczniki diody}
