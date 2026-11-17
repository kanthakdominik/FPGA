# Przegląd ziaren rozmieszczenia (16.04): ten sam projekt, różne wartości SEED Fittera.
# Dla każdego ziarna: Fitter, Timing Analyzer i najgorszy zapas setup ze wszystkich modeli.
# Użycie (po make): quartus_sh -t ziarna.tcl wydajnosc 1 2 3 4 5   (albo: make ziarna)
package require ::quartus::project
package require ::quartus::flow

set projekt [lindex $quartus(args) 0]
set ziarna  [lrange $quartus(args) 1 end]
if {$ziarna eq ""} { set ziarna {1 2 3 4 5} }
file mkdir raporty
set wyj [open raporty/ziarna.txt w]
puts $wyj "ziarno  najgorszy_zapas_setup_ns"

proc najgorszy_zapas {projekt} {
    # plik podsumowania Timing Analyzera: pary "Type : ... Setup ..." / "Slack : x"
    set f [open output_files/$projekt.sta.summary r]
    set min 1e9
    set setup 0
    foreach linia [split [read $f] "\n"] {
        if {[regexp {^Type\s*:\s*(.*)$} $linia -> typ]} { set setup [string match "*Setup*" $typ] }
        if {$setup && [regexp {^Slack\s*:\s*(-?[0-9.]+)} $linia -> s] && $s < $min} { set min $s }
    }
    close $f
    return $min
}

project_open $projekt
foreach s $ziarna {
    set_global_assignment -name SEED $s
    export_assignments
    execute_module -tool fit
    execute_module -tool sta
    set z [najgorszy_zapas $projekt]
    puts "ziarno $s: najgorszy zapas setup $z ns"
    puts $wyj [format "%6d  %8.3f" $s $z]
}
set_global_assignment -name SEED 1
export_assignments
project_close
close $wyj
puts "Wyniki w raporty/ziarna.txt"
