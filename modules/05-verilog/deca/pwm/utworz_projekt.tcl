# Tworzy projekt Quartusa "pwm" dla płytki DECA (moduł 05): osiem diod z różną jasnością.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile pwm
#   quartus_pgm -c 1 -m jtag -o "p;output_files/pwm.sof"
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt pwm $tu {pwm_multi} {MAX10_CLK1_50 diody}
