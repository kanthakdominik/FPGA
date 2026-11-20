# Tworzy projekt Quartusa "naped" dla płytki DECA (moduł 20, 20.04): PWM z czasem martwym (GPIO0_D[2], [3]),
# serwo (GPIO0_D[4]), enkoder kwadraturowy (GPIO0_D[5], [6] z podciąganiem w układzie).
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile naped
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt naped $tu {pwm_mostek serwo enkoder} \
    {MAX10_CLK1_50 przyciski przelaczniki diody GPIO0_D[2] GPIO0_D[3] GPIO0_D[4] GPIO0_D[5] GPIO0_D[6]}

project_open naped
foreach s {GPIO0_D[5] GPIO0_D[6]} {
    set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to $s
}
project_close
