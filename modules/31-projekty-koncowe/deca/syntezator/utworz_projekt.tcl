# Tworzy projekt Quartusa "syntezator" dla płytki DECA (moduł 31, 31.03): MIDI na GPIO0_D[1], kodek audio.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt syntezator $tu {uart_rx midi_parser sin_tab syntezator i2s_master i2c_zapisy projekt_syntezator} {MAX10_CLK1_50 przyciski przelaczniki diody audio GPIO0_D[0] GPIO0_D[1]}
