# Tworzy projekt Quartusa "blink" dla płytki DECA.
#
# Użycie (w tym katalogu):
#   quartus_sh -t utworz_projekt.tcl [vhdl|verilog|sv] [układ]
#   quartus_sh --flow compile blink
#   quartus_pgm -m jtag -o "p;output_files/blink.sof"
#
# Domyślnie: verilog, układ 10M50DAF484C6GES (wersja inżynierska, jak na większości płytek DECA).
# Dla układu bez dopisku ES:  quartus_sh -t utworz_projekt.tcl vhdl 10M50DAF484C6G

package require ::quartus::project

# argumenty skryptu: quartus_sh przekazuje je w $quartus(args)
if {[info exists quartus(args)]} {
    set argumenty $quartus(args)
} else {
    set argumenty $argv
}
set jezyk "verilog"
set uklad "10M50DAF484C6GES"
if {[llength $argumenty] > 0} { set jezyk [lindex $argumenty 0] }
if {[llength $argumenty] > 1} { set uklad [lindex $argumenty 1] }

set tu     [file dirname [file normalize [info script]]]
set hdl    [file normalize [file join $tu .. .. hdl]]
set plytka [file normalize [file join $tu .. .. .. .. plytka-deca]]

source [file join $plytka deca_piny.tcl]

cd $tu
project_new -overwrite blink

deca_ustawienia_ukladu $uklad
set_global_assignment -name TOP_LEVEL_ENTITY deca_top

switch -- $jezyk {
    vhdl {
        set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008
        set_global_assignment -name VHDL_FILE [file join $hdl vhdl blink.vhd]
        set_global_assignment -name VHDL_FILE [file join $tu deca_top.vhd]
    }
    verilog {
        set_global_assignment -name VERILOG_FILE [file join $hdl verilog blink.v]
        set_global_assignment -name VERILOG_FILE [file join $tu deca_top.v]
    }
    sv {
        set_global_assignment -name SYSTEMVERILOG_FILE [file join $hdl sv blink.sv]
        set_global_assignment -name SYSTEMVERILOG_FILE [file join $tu deca_top.sv]
    }
    default {
        error "Nieznany język: $jezyk (dozwolone: vhdl, verilog, sv)"
    }
}

set_global_assignment -name SDC_FILE [file join $tu blink.sdc]

# piny: zegar 50 MHz, przyciski, diody
deca_pin MAX10_CLK1_50
deca_grupa przyciski
deca_grupa diody

project_close
puts "Projekt blink ($jezyk, $uklad) utworzony w $tu"
