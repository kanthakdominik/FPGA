# Tworzy projekt Quartusa "debug" dla płytki DECA (moduł 17): bicie serca z trzech zegarów, miernik
# częstotliwości, mini_ila i In-System Sources and Probes; ograniczenia w debug.sdc.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile debug
# albo: make, make sram, make czestotliwosci, make ila (zob. Makefile)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt debug $tu {bicie_serca pomiar_czestotliwosci mini_ila} \
    {MAX10_CLK1_50 ADC_CLK_10 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1] GPIO0_D[2] GPIO0_D[3]}
