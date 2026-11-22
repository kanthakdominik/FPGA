# Tworzy projekt Quartusa "niosv" dla płytki DECA (moduł 27, 27.02 i 27.03): system Platform Designer
# system_niosv (Nios V/m, pamięć, JTAG UART, PIO, pwm_avl). Plik system_niosv.qip jest dodawany, jeśli istnieje
# — najpierw "make system" (README.md).
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile niosv
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt niosv $tu {} {MAX10_CLK1_50 przyciski diody}

project_open niosv
set qip [file join $tu system_niosv synthesis system_niosv.qip]
if {[file exists $qip]} {
    set_global_assignment -name QIP_FILE $qip
    puts "Dodano system: $qip"
} else {
    puts "UWAGA: brak $qip — uruchom najpierw: make system"
}
project_close
