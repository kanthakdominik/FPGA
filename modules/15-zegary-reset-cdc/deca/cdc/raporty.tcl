# Raporty CDC i metastabilności Timing Analyzera dla projektu "cdc" (15.07). Użycie po kompilacji:
#   quartus_sta -t raporty.tcl cdc        (albo: make raporty)
package require ::quartus::project
package require ::quartus::sta

set projekt [lindex $quartus(args) 0]
if {$projekt eq ""} { set projekt cdc }
project_open $projekt
create_timing_netlist -model slow
read_sdc
update_timing_netlist
file mkdir raporty
proc do_pliku {nazwa} { return [file join raporty $nazwa] }

report_clocks          -file [do_pliku zegary.txt]
report_clock_transfers -file [do_pliku przejscia.txt]
check_timing           -file [do_pliku kontrola.txt]
report_ucp             -file [do_pliku nieograniczone.txt]
report_exceptions      -file [do_pliku wyjatki.txt]
create_timing_summary -setup -file [do_pliku podsumowanie_setup.txt]
create_timing_summary -hold  -file [do_pliku podsumowanie_hold.txt]
# rozrzut i opóźnienia połączeń wskaźników Graya
report_max_skew  -npaths 10 -file [do_pliku max_skew.txt]
report_net_delay -nworst 10 -file [do_pliku net_delay.txt]
# łańcuchy synchronizatorów rozpoznane przez Quartusa i ich MTBF
report_metastability -file [do_pliku mtbf.txt]

delete_timing_netlist
project_close
puts "Raporty zapisane w katalogu raporty/"
