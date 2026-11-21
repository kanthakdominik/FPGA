# Tworzy projekt Quartusa "obraz" dla płytki DECA (moduł 24, 24.04 i 24.06): bufor ramki z podwójnym buforowaniem
# w pamięci na chipie, czytnik linii Avalon-MM, filtr 3×3 i wyjście HDMI przez ADV7513.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt obraz $tu {takt_wideo adv7513_konfig czytnik_linii bufor_ramki filtr3x3} {MAX10_CLK1_50 przyciski przelaczniki diody hdmi}
project_open obraz
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "HDMI_TX_D\[*\]"
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_DE
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_HS
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_VS
project_close
