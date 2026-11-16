# Tworzy projekt Quartusa "blink" dla płytki DECA.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile blink
#   quartus_pgm -c 1 -m jtag -o "p;output_files/blink.sof"
#
# Domyślnie: verilog, układ 10M50DAF484C6GES (wersja inżynierska, jak na większości płytek DECA).
# Dla układu bez dopisku ES:  quartus_sh -t utworz_projekt.tcl vhdl 10M50DAF484C6G

package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]

# nazwa, katalog, moduły z hdl/, piny: zegar 50 MHz, przyciski, diody
deca_utworz_projekt blink $tu {blink} {MAX10_CLK1_50 przyciski diody}
