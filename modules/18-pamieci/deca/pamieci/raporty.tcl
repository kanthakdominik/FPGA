# Raport zasobów pamięci po kompilacji (18.01, 18.02): które pamięci trafiły do bloków M9K, w jakim trybie
# i z jakim plikiem inicjalizacji. Użycie: quartus_sh -t raporty.tcl pamieci   (albo: make raporty)
package require ::quartus::project
package require ::quartus::report
set projekt [lindex $quartus(args) 0]
project_open $projekt
load_report
file mkdir raporty
set f [open raporty/pamieci.txt w]
foreach panel [get_report_panel_names] {
    if {[string match "*RAM Summary*" $panel] || [string match "*Fitter Resource Usage Summary*" $panel]} {
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
puts "Zapisano raporty/pamieci.txt"
