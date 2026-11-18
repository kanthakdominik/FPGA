# Tworzy projekt Quartusa "ufm" dla płytki DECA (moduł 18): sterownik pamięci flash użytkownika
# i licznik naciśnięć zapamiętany w UFM. Wymaga rdzenia ufm_flash wygenerowanego w tym katalogu
# (Platform Designer / IP Catalog — instrukcja w README.md); plik .qip rdzenia jest dodawany, jeśli istnieje.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile ufm
# albo: make, make flash (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt ufm $tu {ufm_sterownik} {MAX10_CLK1_50 przyciski przelaczniki diody}

set qip [lindex [glob -nocomplain -directory $tu ufm_flash/synthesis/ufm_flash.qip ufm_flash.qip] 0]
project_open ufm
if {$qip ne ""} {
    set_global_assignment -name QIP_FILE $qip
    puts "Dodano rdzeń: $qip"
} else {
    puts "UWAGA: brak ufm_flash.qip — wygeneruj rdzeń On-Chip Flash (README.md), potem uruchom skrypt ponownie."
}
project_close
