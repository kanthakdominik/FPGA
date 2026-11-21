# Tworzy projekt Quartusa "audio" dla płytki DECA (moduł 25, 25.01–25.02): kodek TLV320AIC3254 przez I2C i I2S,
# filtr biquad i echo. Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt audio $tu {i2c_zapisy i2s_master biquad echo} {MAX10_CLK1_50 przyciski przelaczniki diody audio}
