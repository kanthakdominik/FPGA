# Tworzy projekt Quartusa "rv" dla płytki DECA (moduł 27, 27.07): własny SoC RISC-V (rv_soc, rv_potok, pwm_avl).
# Program deca_prog.hex/.mif w tym katalogu (python3 ../../program/rvasm.py po zmianie deca.S).
# Użycie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]; albo make, make sram
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt rv $tu {rv_alu rv_dekoder rv_rejestry rv_wyrownanie rv_potok pwm_avl rv_soc} {MAX10_CLK1_50 przyciski przelaczniki diody}
