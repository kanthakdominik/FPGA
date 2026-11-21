# Tworzy projekt Quartusa "qspi" dla płytki DECA (moduł 23, 23.03): odczyt ID i danych z pamięci QSPI flash.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt qspi $tu {qspi_master} {MAX10_CLK1_50 przyciski przelaczniki diody qspi}
