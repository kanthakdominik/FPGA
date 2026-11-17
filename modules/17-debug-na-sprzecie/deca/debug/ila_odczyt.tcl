# Sterowanie mini_ila przez JTAG (17.02, 17.03): ustawienie warunku wyzwolenia, uzbrojenie, czekanie
# na zakończenie, odczyt 256 próbek i zapis do raporty/ila.vcd (do obejrzenia w GTKWave).
# Instancja ISSP "ILA0": źródła {arm, zbocze, pre[7:0], rd_addr[7:0], trig_val[15:0], trig_mask[15:0]},
# sondy {armed, capturing, done, rd_data[15:0]}; próbka = {KEY1 wciśnięty, SW[1:0], licznik[12:0]}.
#
# Użycie: quartus_stp -t ila_odczyt.tcl [trig_val trig_mask zbocze pre]
#   domyślnie: 0x8000 0x8000 1 64 — zbocze naciśnięcia KEY[1], 64 próbki przed nim (albo: make ila)
set tu [file dirname [file normalize [info script]]]
source [file join $tu issp.tcl]

set arg $quartus(args)
set tval   [expr {[llength $arg] > 0 ? [lindex $arg 0] : 0x8000}]
set tmask  [expr {[llength $arg] > 1 ? [lindex $arg 1] : 0x8000}]
set zbocze [expr {[llength $arg] > 2 ? [lindex $arg 2] : 1}]
set pre    [expr {[llength $arg] > 3 ? [lindex $arg 3] : 64}]

proc zrodla {arm zbocze pre addr tval tmask} {
    return "[int2bin $arm 1][int2bin $zbocze 1][int2bin $pre 8][int2bin $addr 8][int2bin $tval 16][int2bin $tmask 16]"
}

lassign [issp_polacz] kabel uklad
set idx [issp_indeks $kabel $uklad ILA0]

# konfiguracja przy arm = 0, potem arm = 1 (zbocze uzbraja), potem arm = 0
write_source_data -instance_index $idx -value [zrodla 0 $zbocze $pre 0 $tval $tmask]
write_source_data -instance_index $idx -value [zrodla 1 $zbocze $pre 0 $tval $tmask]
write_source_data -instance_index $idx -value [zrodla 0 $zbocze $pre 0 $tval $tmask]
puts [format "Uzbrojony: warunek (probe ^ 0x%04X) & 0x%04X == 0, %s, %d próbek przed wyzwoleniem" \
          $tval $tmask [expr {$zbocze ? "zbocze" : "poziom"}] $pre]

# czekanie na zakończenie (bit done = indeks 2 od lewej)
set start [clock seconds]
while {[string index [read_probe_data -instance_index $idx] 2] ne "1"} {
    if {[clock seconds] - $start > 60} {
        end_insystem_source_probe
        error "Brak wyzwolenia w ciągu 60 s"
    }
    after 50
}

# odczyt bufora
set probki {}
for {set a 0} {$a < 256} {incr a} {
    write_source_data -instance_index $idx -value [zrodla 0 $zbocze $pre $a $tval $tmask]
    lappend probki [bin2int [string range [read_probe_data -instance_index $idx] 3 18]]
}
end_insystem_source_probe

# zapis VCD: okres próbkowania 10 ns (zegar 100 MHz); sygnał "wyzwolenie" = 1 w próbce wyzwolenia
file mkdir raporty
set f [open raporty/ila.vcd w]
puts $f "\$timescale 1ns \$end"
puts $f "\$scope module mini_ila \$end"
puts $f "\$var wire 1 k key1_wcisniety \$end"
puts $f "\$var wire 2 s sw \[1:0\] \$end"
puts $f "\$var wire 13 c licznik \[12:0\] \$end"
puts $f "\$var wire 1 t wyzwolenie \$end"
puts $f "\$upscope \$end"
puts $f "\$enddefinitions \$end"
for {set i 0} {$i < 256} {incr i} {
    set p [lindex $probki $i]
    puts $f "#[expr {$i * 10}]"
    puts $f "[expr {($p >> 15) & 1}]k"
    puts $f "b[int2bin [expr {($p >> 13) & 3}] 2] s"
    puts $f "b[int2bin [expr {$p & 0x1FFF}] 13] c"
    puts $f "[expr {$i == $pre ? 1 : 0}]t"
}
close $f

# kontrola: licznik musi rosnąć o 1 w każdej próbce
set bledy 0
for {set i 1} {$i < 256} {incr i} {
    set d [expr {(([lindex $probki $i] & 0x1FFF) - ([lindex $probki [expr {$i - 1}]] & 0x1FFF)) & 0x1FFF}]
    if {$d != 1} { incr bledy }
}
puts [format "Próbka wyzwolenia: 0x%04X; nieciągłości licznika: %d (powinno być 0)" [lindex $probki $pre] $bledy]
puts "Zapisano raporty/ila.vcd (gtkwave raporty/ila.vcd)"
