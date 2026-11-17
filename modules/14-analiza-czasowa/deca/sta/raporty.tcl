# Raporty Timing Analyzera dla projektu "sta" (14.05). Użycie po kompilacji:
#   quartus_sta -t raporty.tcl sta        (albo: make raporty)
# Wyniki w katalogu raporty/: *.txt do czytania i porównania z opisem w 14.05 i 14.06.
package require ::quartus::project
package require ::quartus::sta

set projekt [lindex $quartus(args) 0]
if {$projekt eq ""} { set projekt sta }
project_open $projekt
create_timing_netlist -model slow
read_sdc
update_timing_netlist
file mkdir raporty

proc do_pliku {nazwa} { return [file join raporty $nazwa] }

# Kontrola ograniczeń: zegary, nieograniczone ścieżki, wyjątki.
report_clocks              -file [do_pliku zegary.txt]
check_timing               -file [do_pliku kontrola.txt]
report_ucp                 -file [do_pliku nieograniczone.txt]
report_exceptions          -file [do_pliku wyjatki.txt]
report_clock_transfers     -file [do_pliku przejscia.txt]

# Podsumowanie setup/hold dla wszystkich zegarów i najgorsze ścieżki w każdej domenie.
create_timing_summary -setup -file [do_pliku podsumowanie_setup.txt]
create_timing_summary -hold  -file [do_pliku podsumowanie_hold.txt]
report_timing -setup -npaths 10 -detail full_path -file [do_pliku setup_10.txt]
report_timing -hold  -npaths 10 -detail full_path -file [do_pliku hold_10.txt]

# Ścieżki z tego modułu: dzielnik wielotaktowy, wyjścia i wejście SPI.
report_timing -setup -npaths 3 -detail full_path -from [get_registers {*u_dziel|a_r[*]}] \
              -to [get_registers {*u_dziel|q[*]}] -file [do_pliku dzielnik_setup.txt]
report_timing -hold  -npaths 3 -detail full_path -from [get_registers {*u_dziel|a_r[*]}] \
              -to [get_registers {*u_dziel|q[*]}] -file [do_pliku dzielnik_hold.txt]
foreach t {setup hold} {
    report_timing -$t -npaths 3 -detail full_path -to [get_ports {GPIO0_D[1] GPIO0_D[2]}] \
                  -file [do_pliku spi_wyjscia_$t.txt]
    report_timing -$t -npaths 3 -detail full_path -from [get_ports {GPIO0_D[3]}] \
                  -file [do_pliku spi_wejscie_$t.txt]
}
report_fmax_summary -file [do_pliku fmax.txt]

delete_timing_netlist
project_close
puts "Raporty zapisane w katalogu raporty/"
