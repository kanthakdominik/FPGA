# Test skryptów JTAG bez płytki (CI): atrapy poleceń quartus_stp (::quartus::stp, insystem_source_probe)
# z prostym modelem sprzętu — instancja ILA0 po uzbrojeniu od razu kończy zapis, a rd_data zwraca
# kolejne wartości licznika; FREQ zwraca 10000 i 100000 taktów. Sprawdza układ bitów źródeł i sond,
# konwersje i plik VCD. Uruchomienie: tclsh test_skryptow.tcl
set tu [file dirname [file normalize [info script]]]
set ::blad_testu 0
proc sprawdz {warunek opis} {
    if {![uplevel 1 [list expr $warunek]]} { puts "BLAD: $opis"; incr ::blad_testu } else { puts "OK   $opis" }
}

# --- atrapy ---
set ::zrodla [string repeat 0 50]
set ::uzbrojony 0
set ::zapisy 0
proc get_hardware_names {} { return [list "USB-Blaster \[USB-0\]"] }
proc get_device_names {args} { return [list "@1: 10M50DA(.|ES)/10M50DC (0x031050DD)"] }
proc start_insystem_source_probe {args} {}
proc end_insystem_source_probe {} {}
proc get_insystem_source_probe_instance_info {args} { return {{0 50 19 ILA0} {1 1 48 FREQ}} }
proc write_source_data {args} {
    array set o $args
    if {[string length $o(-value)] != 50} { error "zła szerokość źródeł: [string length $o(-value)]" }
    if {[string index $o(-value) 0] eq "1"} { set ::uzbrojony 1 }
    set ::zrodla $o(-value)
    incr ::zapisy
}
proc read_probe_data {args} {
    array set o $args
    if {$o(-instance_index) == 1} {
        return "[int2bin 10000 24][int2bin 100000 24]"
    }
    set addr [bin2int [string range $::zrodla 10 17]]
    set dane [expr {($addr == 64 ? 0x8000 : 0) | 0x2000 | ((0x0100 + $addr) & 0x1FFF)}]
    return "00$::uzbrojony[int2bin $dane 16]"
}

# --- czestotliwosci.tcl ---
set quartus(args) {}
source [file join $tu czestotliwosci.tcl]
sprawdz {$f10 == 10000 && $f100 == 100000} "czestotliwosci.tcl: odczyt f10 i f100 z 48 bitów sondy"

# --- ila_odczyt.tcl w katalogu tymczasowym ---
set tmp [file join $tu build_test]
file mkdir $tmp
cd $tmp
set quartus(args) {0x8000 0x8000 1 64}
source [file join $tu ila_odczyt.tcl]
sprawdz {$::uzbrojony == 1} "ila_odczyt.tcl: zbocze arm wysłane"
sprawdz {[string range $::zrodla 2 9] eq [int2bin 64 8]} "pre = 64 w bitach 47..40"
sprawdz {[string range $::zrodla 18 33] eq [int2bin 0x8000 16]} "trig_val w bitach 31..16"
sprawdz {[llength $probki] == 256 && $bledy == 0} "256 próbek, licznik ciągły"
sprawdz {[lindex $probki 64] == (0x8000 | 0x2000 | 0x0140)} "próbka wyzwolenia na pozycji pre"
set vcd [read [open raporty/ila.vcd]]
sprawdz {[regexp {#2550\n} $vcd] && [regexp {\$var wire 13 c licznik} $vcd]} "plik VCD: 256 chwil, zmienne"
cd $tu
file delete -force $tmp
puts [expr {$::blad_testu == 0 ? "PASS" : "FAIL: $::blad_testu"}]
exit [expr {$::blad_testu != 0}]
