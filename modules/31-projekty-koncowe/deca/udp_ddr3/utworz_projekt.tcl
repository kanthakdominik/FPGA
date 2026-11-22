# Tworzy projekt Quartusa "udp_ddr3" dla płytki DECA (moduł 31, 31.04): Nios V/m + udp_dma + PHY Ethernet.
# Najpierw system Platform Designer: make system (qsys-script + qsys-generate), potem ten skrypt doda jego .qip.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt udp_ddr3 $tu {} {MAX10_CLK1_50 przyciski diody ethernet}

project_open udp_ddr3
set qip [file join $tu system_udp synthesis system_udp.qip]
if {[file exists $qip]} {
    set_global_assignment -name QIP_FILE $qip
    puts "Dodano system: $qip"
} else {
    puts "UWAGA: brak $qip — uruchom najpierw: make system"
}
project_close
