# Tworzy projekt Quartusa "udp" dla płytki DECA (moduł 25, 25.03–25.05): PHY Ethernet przez MII, ARP i strumień
# datagramów UDP do komputera. Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt udp $tu {mdio mii_tx mii_rx arp_odp udp_nad} {MAX10_CLK1_50 przyciski przelaczniki diody ethernet}
project_open udp
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "NET_TXD\[*\]"
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to NET_TX_EN
set_instance_assignment -name FAST_INPUT_REGISTER ON -to "NET_RXD\[*\]"
set_instance_assignment -name FAST_INPUT_REGISTER ON -to NET_RX_DV
set_instance_assignment -name FAST_INPUT_REGISTER ON -to NET_RX_ER
project_close
