# Tworzy projekt Quartusa "oscyloskop" dla płytki DECA (moduł 31, 31.02): ADC MAX 10 (kanał 1) i obraz HDMI.
# Wymaga rdzeni adc_pll (ALTPLL 10 MHz -> 10 MHz) i adc_rdzen (Modular ADC Core, „ADC Control Core Only”,
# kanał CH1, 1 MSPS) wygenerowanych w tym katalogu tak jak w module 20 (README.md); ich .qip są dodawane,
# jeśli istnieją.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile oscyloskop
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt oscyloskop $tu {adc_sekwencer takt_wideo adv7513_konfig zrzut ram_2z ekran_osc oscyloskop} {MAX10_CLK1_50 ADC_CLK_10 przyciski przelaczniki diody hdmi}

project_open oscyloskop
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to "HDMI_TX_D\[*\]"
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_DE
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_HS
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to HDMI_TX_VS
foreach rdzen {adc_pll adc_rdzen} {
    set qip [lindex [glob -nocomplain -directory $tu $rdzen.qip $rdzen/synthesis/$rdzen.qip] 0]
    if {$qip ne ""} {
        set_global_assignment -name QIP_FILE $qip
        puts "Dodano rdzeń: $qip"
    } else {
        puts "UWAGA: brak $rdzen.qip — wygeneruj rdzeń (README.md), potem uruchom skrypt ponownie."
    }
}
project_close
