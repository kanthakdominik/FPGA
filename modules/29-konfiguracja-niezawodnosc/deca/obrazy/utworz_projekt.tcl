# Tworzy projekt Quartusa "obrazy" dla DECA (moduł 29, 29.02): moduł nadrzędny z parametrem OBRAZ (zmienna
# środowiskowa OBRAZ=0 albo 1, domyślnie 0), tryb konfiguracji Dual Compressed Images i system_dual
# (po "make system"). Pełna procedura: README.md (make obraz0, make obraz1, konwersja do .pof).
package require ::quartus::project
set tu [file dirname [file normalize [info script]]]
source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
deca_utworz_projekt obrazy $tu {crc32 aktualizacja} {MAX10_CLK1_50 przyciski przelaczniki diody}

set obraz [expr {[info exists ::env(OBRAZ)] ? $::env(OBRAZ) : 0}]
project_open obrazy
set_parameter -name OBRAZ $obraz
set_global_assignment -name INTERNAL_FLASH_UPDATE_MODE "DUAL IMAGES"
set qip [file join $tu system_dual synthesis system_dual.qip]
if {[file exists $qip]} {
    set_global_assignment -name QIP_FILE $qip
} else {
    puts "UWAGA: brak $qip — uruchom najpierw: make system"
}
project_close
puts "OBRAZ = $obraz"
