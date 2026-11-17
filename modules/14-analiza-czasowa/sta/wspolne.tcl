# Wspólne procedury eksperymentów OpenSTA (moduł 14). Dołączane przez e0*.tcl.
# Zmienna środowiskowa LIB_DIR: katalog z nangate45_slow.lib i nangate45_fast.lib.

# Biblioteka wolna (SS) do analizy setup, szybka (FF) do analizy hold — jedna "scena" min/max.
proc wczytaj {} {
    read_liberty $::env(LIB_DIR)/nangate45_slow.lib
    read_liberty $::env(LIB_DIR)/nangate45_fast.lib
    read_verilog build/sta_demo_net.v
    link_design sta_demo
    define_scene domyslna -liberty_min NangateOpenCellLibrary_fast -liberty_max NangateOpenCellLibrary_slow
}

# Przerzutniki rejestru. Synteza nadaje im nazwy <rejestr>[<bit>]_reg (Yosys: rename -wire -suffix _reg),
# np. [rejestry u_dziel.a_r] — wszystkie bity a_r w instancji u_dziel; [bit u_spi.sh_rx 1] — jeden bit.
proc rejestry {rejestr} {
    set re "^[string map {. \\. \[ \\\[ \] \\\]} $rejestr](\\\[\[0-9\]+\\\])?_reg\$"
    set wynik {}
    foreach c [get_cells "${rejestr}*_reg"] {
        if {[regexp $re [get_full_name $c]]} { lappend wynik $c }
    }
    return $wynik
}

proc bit {rejestr n} {
    return [get_cells "${rejestr}\[$n\]_reg"]
}

# Wyjście Q przerzutnika rejestru (do definicji zegara generowanego).
proc wyjscie_q {rejestr} {
    return [get_pins "[get_full_name [lindex [rejestry $rejestr] 0]]/Q"]
}

# Raport najgorszej ścieżki w sekcji oznaczonej znacznikiem — czyta go sprawdz_sta.py.
proc sciezka {etykieta typ args} {
    puts "### $etykieta"
    report_checks -path_delay $typ -digits 3 -format full_clock_expanded {*}$args
    puts "### koniec"
}
