# Wspólne procedury In-System Sources and Probes dla skryptów quartus_stp (moduł 17).
# Źródła i sondy są czytane/zapisywane jako ciągi bitów, najstarszy bit po lewej.

# Pierwszy kabel JTAG i pierwszy układ MAX 10 w łańcuchu (DECA ma jeden: 10M50).
proc issp_polacz {} {
    set kabel [lindex [get_hardware_names] 0]
    if {$kabel eq ""} { error "Brak kabla JTAG (sprawdź: jtagconfig)" }
    set uklad ""
    foreach d [get_device_names -hardware_name $kabel] {
        if {[string match "*10M50*" $d]} { set uklad $d }
    }
    if {$uklad eq ""} { error "Brak układu 10M50 w łańcuchu JTAG kabla $kabel" }
    start_insystem_source_probe -hardware_name $kabel -device_name $uklad
    return [list $kabel $uklad]
}

# Indeks instancji o danym identyfikatorze (instance_id z HDL, np. ILA0).
proc issp_indeks {kabel uklad nazwa} {
    foreach inst [get_insystem_source_probe_instance_info -hardware_name $kabel -device_name $uklad] {
        lassign $inst indeks szer_zr szer_sondy id
        if {$id eq $nazwa} { return $indeks }
    }
    error "Brak instancji ISSP o nazwie $nazwa"
}

proc bin2int {bity} {
    set w 0
    foreach b [split $bity ""] { set w [expr {$w * 2 + $b}] }
    return $w
}

proc int2bin {wartosc szer} {
    set s ""
    for {set i [expr {$szer - 1}]} {$i >= 0} {incr i -1} {
        append s [expr {($wartosc >> $i) & 1}]
    }
    return $s
}

# Odczyt sondy dwa razy do skutku — wartość wielobitowa może zmienić się w trakcie odczytu.
proc issp_czytaj_stabilnie {indeks} {
    set a [read_probe_data -instance_index $indeks]
    while {1} {
        set b [read_probe_data -instance_index $indeks]
        if {$a eq $b} { return $b }
        set a $b
    }
}
