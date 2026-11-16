# Sprawdzenie wyników analizy czasowej skompilowanego projektu we wszystkich modelach pracy.
#
# Użycie (w katalogu projektu, po kompilacji):
#   quartus_sta -t ../../../../plytka-deca/sprawdz_czasy.tcl <projekt>
#
# Wypisuje najgorszy zapas setup i hold dla każdego modelu (np. Slow 1200mV 85C)
# i kończy się kodem błędu, jeśli którykolwiek zapas jest ujemny — do użycia w make i CI.

package require ::quartus::project
package require ::quartus::sta

set projekt [lindex $quartus(args) 0]
if {$projekt eq ""} {
    puts "Użycie: quartus_sta -t sprawdz_czasy.tcl <projekt>"
    qexit -error
}

project_open $projekt
create_timing_netlist
read_sdc
update_timing_netlist

set bledy 0
foreach_in_collection warunki [get_available_operating_conditions] {
    set_operating_conditions $warunki
    update_timing_netlist
    set nazwa [get_operating_conditions_info $warunki -display_name]
    # report_timing zwraca listę: {liczba ścieżek, najgorszy zapas}
    set setup [lindex [report_timing -setup -npaths 1 -detail summary -panel_name "Setup: $nazwa"] 1]
    set hold  [lindex [report_timing -hold  -npaths 1 -detail summary -panel_name "Hold: $nazwa"] 1]
    puts [format "%-24s setup: %8s ns   hold: %8s ns" $nazwa $setup $hold]
    foreach zapas [list $setup $hold] {
        if {$zapas ne "" && $zapas < 0} { incr bledy }
    }
}

delete_timing_netlist
project_close

if {$bledy > 0} {
    puts "FAIL: ujemny zapas czasowy ($bledy)"
    qexit -error
}
puts "PASS: wymagania czasowe spełnione"
qexit -success
