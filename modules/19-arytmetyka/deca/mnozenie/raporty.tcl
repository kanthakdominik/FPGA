# Raporty po kompilacji projektu "mnozenie" (19.02): użycie bloków mnożarek (ile elementów 9 × 9 i 18 × 18
# zajęła każda mnożarka), podsumowanie zasobów i f_max. Użycie: quartus_sh -t raporty.tcl mnozenie
# (albo: make raporty). Wynik: raporty/mnozenie.txt
package require ::quartus::project
package require ::quartus::report
set projekt [lindex $quartus(args) 0]
project_open $projekt
load_report
file mkdir raporty
set f [open raporty/mnozenie.txt w]
foreach panel [get_report_panel_names] {
    if {[string match "*DSP Block Usage Summary*" $panel] || [string match "*Embedded Multiplier*" $panel]
        || [string match "*Fitter Resource Usage Summary*" $panel] || [string match "*Fmax Summary*" $panel]} {
        puts $f "== $panel"
        set wiersze [get_number_of_rows -name $panel]
        for {set i 0} {$i < $wiersze} {incr i} {
            puts $f [join [get_report_panel_row -name $panel -row $i] " | "]
        }
        puts $f ""
    }
}
close $f
unload_report
project_close
puts "Zapisano raporty/mnozenie.txt"
