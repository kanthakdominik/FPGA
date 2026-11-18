# Tworzy projekt Quartusa "pamieci" dla płytki DECA (moduł 18): rom_sinus (M9K, zawartość z pliku),
# ram_sdp z dwoma zegarami i PWM na diodach; ograniczenia w pamieci.sdc.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile pamieci
# albo: make, make sram, make raporty (zob. Makefile)
# Pliki zawartości: ../../hdl/dane/sinus.hex ($readmemh w Verilogu/SV) i sinus.mif (atrybut w VHDL);
# po zmianie tablicy: python3 ../../hdl/dane/gen_sinus.py i ponowna kompilacja.
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt pamieci $tu {rom_sinus ram_sdp} {MAX10_CLK1_50 ADC_CLK_10 przyciski przelaczniki diody}
