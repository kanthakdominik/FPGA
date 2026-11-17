# Tworzy projekt Quartusa "wydajnosc" dla płytki DECA (moduł 16): PLL 150 MHz, drzewo sumatorów
# z potokiem (PIPE) i mnożarka z izolacją argumentów (ISO); ograniczenia w wydajnosc.sdc.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile wydajnosc
# albo: make, make czas, make ziarna, make moc (zob. plytka-deca/deca.mk i Makefile)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt wydajnosc $tu {sumator_drzewo izolacja_operandow} {MAX10_CLK1_50 przyciski przelaczniki diody}
