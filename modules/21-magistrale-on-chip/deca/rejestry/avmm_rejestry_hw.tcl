# Opis komponentu Platform Designer dla avmm_rejestry (21.06): interfejsy zegara, resetu, slave Avalon-MM
# (adresy słów, opóźnienie odczytu 1 takt, sygnał response) i conduit z sygnałami układu.
# Plik w katalogu projektu jest znajdowany przez Platform Designer (ścieżka wyszukiwania "./,$").
package require -exact qsys 16.1

set_module_property NAME avmm_rejestry
set_module_property DISPLAY_NAME "Rejestry kursu FPGA (21.02)"
set_module_property DESCRIPTION "Mapa rejestrów ID, STER, STAN, PRZER (W1C), MASKA, SKRYTKA"
set_module_property VERSION 1.0
set_module_property GROUP "Kurs FPGA"
set_module_property AUTHOR "Kurs FPGA"
set_module_property EDITABLE false
set_module_property INTERNAL false

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL avmm_rejestry
add_fileset_file avmm_rejestry.v  VERILOG PATH ../../hdl/verilog/avmm_rejestry.v TOP_LEVEL_FILE
add_fileset_file rejestry_rdzen.v VERILOG PATH ../../hdl/verilog/rejestry_rdzen.v

add_parameter ID STD_LOGIC_VECTOR 0x21020001
set_parameter_property ID WIDTH 32
set_parameter_property ID HDL_PARAMETER true
set_parameter_property ID DISPLAY_NAME "Wartość rejestru ID"

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
add_interface_port s0 address    address    Input  4
add_interface_port s0 read       read       Input  1
add_interface_port s0 write      write      Input  1
add_interface_port s0 writedata  writedata  Input  32
add_interface_port s0 byteenable byteenable Input  4
add_interface_port s0 readdata   readdata   Output 32
add_interface_port s0 response   response   Output 2

add_interface uklad conduit end
set_interface_property uklad associatedClock zegar
add_interface_port uklad ster  ster  Output 32
add_interface_port uklad stan  stan  Input  32
add_interface_port uklad zdarz zdarz Input  8
add_interface_port uklad irq   irq   Output 1
