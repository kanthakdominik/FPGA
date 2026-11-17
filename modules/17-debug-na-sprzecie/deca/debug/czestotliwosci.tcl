# Odczyt miernika częstotliwości przez JTAG (17.01, 17.03): instancja ISSP "FREQ" zawiera
# {f10[23:0], f100[23:0]} — liczby taktów zegarów 10 MHz i 100 MHz w oknie 1 ms zegara 50 MHz.
# Użycie (płytka zaprogramowana projektem debug): quartus_stp -t czestotliwosci.tcl   (albo: make czestotliwosci)
set tu [file dirname [file normalize [info script]]]
source [file join $tu issp.tcl]

lassign [issp_polacz] kabel uklad
set idx [issp_indeks $kabel $uklad FREQ]
set bity [issp_czytaj_stabilnie $idx]
set f10  [bin2int [string range $bity 0 23]]
set f100 [bin2int [string range $bity 24 47]]
end_insystem_source_probe

puts [format "ADC_CLK_10:  %8d taktów / 1 ms = %.3f MHz (oczekiwane 10,000)" $f10  [expr {$f10  / 1000.0}]]
puts [format "PLL clk100:  %8d taktów / 1 ms = %.3f MHz (oczekiwane 100,000)" $f100 [expr {$f100 / 1000.0}]]
puts "Dokładność: ±1 takt na okno (±0,001 MHz) plus dokładność oscylatora 50 MHz."
