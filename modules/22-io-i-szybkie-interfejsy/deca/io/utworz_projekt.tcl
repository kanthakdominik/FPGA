# Tworzy projekt Quartusa "io" dla płytki DECA (moduł 22, 22.01 i 22.02): cztery wyjścia 25 MHz z różną siłą
# i szybkością zboczy, zegar i dane DDR, wejście DDR w pętli przez zworę.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile io
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt io $tu {prbs7 prbs7_spr} \
    {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[0] GPIO0_D[1] GPIO0_D[2] GPIO0_D[3] GPIO0_D[4] GPIO0_D[5] GPIO0_D[6]}

project_open io
# 22.01: siła sterowania i szybkość zboczy (MAX 10, 3.3-V LVTTL: 4 albo 8 mA; SLEW_RATE 0 — wolno, 2 — szybko)
foreach {pin prad zbocze} {0 4MA 0  1 4MA 2  2 8MA 0  3 8MA 2  4 8MA 2  5 8MA 2} {
    set_instance_assignment -name CURRENT_STRENGTH_NEW $prad -to "GPIO0_D\[$pin\]"
    set_instance_assignment -name SLEW_RATE $zbocze -to "GPIO0_D\[$pin\]"
}
# rejestry wyjściowe i wejściowe w bloku I/O (dla ALTDDIO to i tak jedyne miejsce)
set_instance_assignment -name FAST_INPUT_REGISTER ON -to "GPIO0_D\[6\]"
project_close
