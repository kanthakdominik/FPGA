# Tworzy projekt Quartusa "sd" dla płytki DECA (moduł 23, 23.05): karta microSD w trybie SPI, odczyt bloku 0.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt sd $tu {sd_spi} {MAX10_CLK1_50 przyciski przelaczniki diody microsd}
