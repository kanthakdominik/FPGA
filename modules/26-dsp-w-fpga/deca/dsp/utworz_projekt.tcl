# Tworzy projekt Quartusa "dsp" dla płytki DECA (moduł 26, 26.01 i 26.03): NCO, filtr FIR i dwa przetworniki
# sigma-delta na złączu GPIO0. Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt dsp $tu {dsp_pkg sin_tab nco fir_transp sd_dac} {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1]}
