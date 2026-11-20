# Tworzy projekt Quartusa "rejestry" dla płytki DECA (moduł 21, 21.02 i 21.06): system Platform Designer
# system_rej (JTAG to Avalon Master Bridge + avmm_rejestry). Plik system_rej.qip jest dodawany, jeśli istnieje
# — najpierw "make system" (README.md). Rdzeń rejestrów trafia do projektu przez system, nie bezpośrednio.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile rejestry
# albo: make system, make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt rejestry $tu {} {MAX10_CLK1_50 przyciski przelaczniki diody}

project_open rejestry
set qip [file join $tu system_rej synthesis system_rej.qip]
if {[file exists $qip]} {
    set_global_assignment -name QIP_FILE $qip
    puts "Dodano system: $qip"
} else {
    puts "UWAGA: brak $qip — uruchom najpierw: make system"
}
project_close
