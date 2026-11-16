# Tworzy projekt Quartusa "logika" dla płytki DECA (moduł 01, bez zegara).
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile logika
#   quartus_pgm -c 1 -m jtag -o "p;output_files/logika.sof"
#
# Domyślnie: verilog, układ 10M50DAF484C6GES (wersja inżynierska, jak na większości płytek DECA).
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt logika $tu {util_pkg full_adder rca_adder decoder comparator} {przelaczniki przyciski diody}
