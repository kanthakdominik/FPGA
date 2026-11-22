# Tworzy projekt Quartusa "rv_mcu" dla płytki DECA (moduł 31, 31.06): rv_mcu z programem mcu_deca.mif/.hex
# (program/zloz.py), UART na GPIO0_D[0] (TX) i GPIO0_D[1] (RX).
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt rv_mcu $tu {rv_alu rv_dekoder rv_rejestry rv_wyrownanie rv_potok pwm_avl uart_rx uart_tx rv_mcu} {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1]}
