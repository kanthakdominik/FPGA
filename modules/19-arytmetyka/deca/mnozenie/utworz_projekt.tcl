# Tworzy projekt Quartusa "mnozenie" dla płytki DECA (moduł 19, 19.02): test mnożarek 34 × 34 i zespolonych
# na danych z LFSR; ograniczenia w mnozenie.sdc.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile mnozenie
# albo: make, make sram, make raporty (zob. Makefile)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt mnozenie $tu {mnoz_potok mnoz_szeroki mnoz_zesp} {MAX10_CLK1_50 przyciski przelaczniki diody}
