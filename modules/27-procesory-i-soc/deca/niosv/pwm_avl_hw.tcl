# Opis komponentu Platform Designer dla pwm_avl (27.03): zegar, reset (aktywny wysoki, zwalniany synchronicznie),
# slave Avalon-MM (adresy słów, opóźnienie odczytu 1 takt, bez byteenable i waitrequest), nadajnik przerwania
# związany ze slave'em i conduit z wyjściem PWM. Plik w katalogu projektu — Platform Designer znajduje go
# przez ścieżkę wyszukiwania "./,$". Wzorzec: modules/21-magistrale-on-chip/deca/rejestry/avmm_rejestry_hw.tcl.
package require -exact qsys 16.1

set_module_property NAME pwm_avl
set_module_property DISPLAY_NAME "PWM kursu FPGA (27.03)"
set_module_property DESCRIPTION "PWM: STER, OKRES, WYPELN, STATUS (W1C), przerwanie na końcu okresu"
set_module_property VERSION 1.0
set_module_property GROUP "Kurs FPGA"
set_module_property AUTHOR "Kurs FPGA"
set_module_property EDITABLE false
set_module_property INTERNAL false

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL pwm_avl
add_fileset_file pwm_avl.v VERILOG PATH ../../hdl/verilog/pwm_avl.v TOP_LEVEL_FILE

add_interface zegar clock end
add_interface_port zegar clk clk Input 1

add_interface reset reset end
set_interface_property reset associatedClock zegar
set_interface_property reset synchronousEdges DEASSERT
add_interface_port reset rst reset Input 1

add_interface s0 avalon end
set_interface_property s0 associatedClock zegar
set_interface_property s0 associatedReset reset
set_interface_property s0 addressUnits WORDS
set_interface_property s0 readLatency 1
set_interface_property s0 readWaitTime 0
set_interface_property s0 writeWaitTime 0
set_interface_property s0 maximumPendingReadTransactions 0
add_interface_port s0 address   address   Input  2
add_interface_port s0 read      read      Input  1
add_interface_port s0 write     write     Input  1
add_interface_port s0 writedata writedata Input  32
add_interface_port s0 readdata  readdata  Output 32

add_interface przerwanie interrupt end
set_interface_property przerwanie associatedAddressablePoint s0
set_interface_property przerwanie associatedClock zegar
set_interface_property przerwanie associatedReset reset
add_interface_port przerwanie irq irq Output 1

add_interface wyjscie conduit end
set_interface_property wyjscie associatedClock zegar
add_interface_port wyjscie pwm pwm Output 1
