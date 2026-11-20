# Tworzy projekt Quartusa "adc" dla płytki DECA (moduł 20, 20.06): wbudowany ADC MAX 10 — kanał 1 (ADC1IN1)
# i termodioda. Wymaga rdzeni adc_pll (ALTPLL) i adc_rdzen (Modular ADC Core, „ADC Control Core Only”)
# wygenerowanych w tym katalogu (README.md); ich pliki .qip są dodawane, jeśli istnieją.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile adc
# albo: make, make sram (zob. plytka-deca/deca.mk)
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt adc $tu {adc_sekwencer adc_srednia tsd_temperatura} {ADC_CLK_10 przyciski przelaczniki diody}

project_open adc
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
