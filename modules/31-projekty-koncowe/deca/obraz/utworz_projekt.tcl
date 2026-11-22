# Tworzy projekt Quartusa "obraz" dla płytki DECA (moduł 31, 31.05): generator RAW Bayer -> isp -> HDMI.
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt obraz $tu {takt_wideo adv7513_konfig filtr3x3 wzor_bayer demozaika isp projekt_obraz} {MAX10_CLK1_50 przyciski przelaczniki diody hdmi}

project_open obraz
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "HDMI_TX_D\[*\]"
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_DE
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_HS
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_VS
project_close
