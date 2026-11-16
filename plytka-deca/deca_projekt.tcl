# Wspólna procedura tworzenia projektów Quartusa dla płytki DECA.
#
# Skrypt projektu (deca/<projekt>/utworz_projekt.tcl) wygląda tak:
#   package require ::quartus::project
#   set tu [file dirname [file normalize [info script]]]
#   source [file join $tu .. .. .. .. plytka-deca deca_projekt.tcl]
#   deca_utworz_projekt <nazwa> $tu {<moduły z hdl/>} {<piny i grupy pinów>}
#
# Wywołanie: quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   - moduły: nazwy plików z katalogu hdl/<język>/ modułu bez rozszerzenia; brakujące w danym języku
#     są pomijane (np. pakiet VHDL),
#   - moduł nadrzędny: deca_top.<rozszerzenie> z katalogu projektu,
#   - ograniczenia: wszystkie pliki *.sdc z katalogu projektu,
#   - piny: nazwy sygnałów (MAX10_CLK1_50, KEY[0]) albo grup (diody, przyciski) z deca_piny.tcl.

set ::DECA_KATALOG [file dirname [file normalize [info script]]]
source [file join $::DECA_KATALOG deca_piny.tcl]

# Język i układ z argumentów skryptu (quartus_sh przekazuje je w $quartus(args)).
proc deca_argumenty {} {
    global quartus argv
    if {[info exists quartus(args)]} {
        set a $quartus(args)
    } elseif {[info exists argv]} {
        set a $argv
    } else {
        set a {}
    }
    set jezyk "verilog"
    set uklad "10M50DAF484C6GES"
    if {[llength $a] > 0} { set jezyk [lindex $a 0] }
    if {[llength $a] > 1} { set uklad [lindex $a 1] }
    return [list $jezyk $uklad]
}

# Przypisanie listy sygnałów i grup sygnałów.
proc deca_przypisz {elementy} {
    set grupy [list]
    dict for {sygnal opis} $::DECA_PINY {
        lappend grupy [lindex $opis 2]
    }
    foreach e $elementy {
        if {$e in $grupy} {
            deca_grupa $e
        } else {
            deca_pin $e
        }
    }
}

proc deca_utworz_projekt {nazwa katalog moduly piny} {
    lassign [deca_argumenty] jezyk uklad
    switch -- $jezyk {
        vhdl    { set rozsz vhd; set typ VHDL_FILE }
        verilog { set rozsz v;   set typ VERILOG_FILE }
        sv      { set rozsz sv;  set typ SYSTEMVERILOG_FILE }
        default { error "Nieznany język: $jezyk (dozwolone: vhdl, verilog, sv)" }
    }
    set hdl [file normalize [file join $katalog .. .. hdl $jezyk]]

    cd $katalog
    project_new -overwrite $nazwa
    deca_ustawienia_ukladu $uklad
    set_global_assignment -name TOP_LEVEL_ENTITY deca_top
    if {$jezyk eq "vhdl"} {
        set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
    }
    foreach m $moduly {
        set plik [file join $hdl $m.$rozsz]
        if {[file exists $plik]} {
            set_global_assignment -name $typ $plik
        }
    }
    set_global_assignment -name $typ [file join $katalog deca_top.$rozsz]
    foreach sdc [lsort [glob -nocomplain -directory $katalog *.sdc]] {
        set_global_assignment -name SDC_FILE $sdc
    }
    deca_przypisz $piny
    project_close
    puts "Projekt $nazwa ($jezyk, $uklad) utworzony w $katalog"
}
