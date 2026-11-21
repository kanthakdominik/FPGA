# Tworzy projekt Quartusa "hdmi" dla płytki DECA (moduł 24, 24.01–24.03): obraz 640×480 przez ADV7513 —
# taktowanie, konfiguracja I2C, tło, tekst, sprite i odcinki.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt hdmi $tu {takt_wideo adv7513_konfig znaki sprite16 linia_bres} {MAX10_CLK1_50 przyciski przelaczniki diody hdmi}
project_open hdmi
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "HDMI_TX_D\[*\]"
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_DE
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_HS
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_VS
project_close
