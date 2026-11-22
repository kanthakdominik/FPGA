# Opis komponentu Platform Designer dla udp_dma (31.04): zegar i reset systemu, slave Avalon-MM z rejestrami
# (adresy słów, opóźnienie odczytu 1), master Avalon-MM odczytu (potokowy, readdatavalid, bez burstów),
# przerwanie, osobny zegar i reset nadawania MII (zegar z PHY) oraz conduit z linią TXD/TX_EN.
package require -exact qsys 16.1

set_module_property NAME udp_dma
set_module_property DISPLAY_NAME "UDP z pamięci (31.04)"
set_module_property DESCRIPTION "Datagramy UDP/IPv4 z bufora w pamięci przez MII, przerwanie po wysłaniu ramki"
set_module_property VERSION 1.0
set_module_property GROUP "Kurs FPGA"
set_module_property AUTHOR "Kurs FPGA"
set_module_property EDITABLE false
set_module_property INTERNAL false

add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL udp_dma
add_fileset_file udp_dma.v    VERILOG PATH ../../hdl/verilog/udp_dma.v TOP_LEVEL_FILE
add_fileset_file udp_nad.v    VERILOG PATH ../../hdl/verilog/udp_nad.v
add_fileset_file async_fifo.v VERILOG PATH ../../hdl/verilog/async_fifo.v
add_fileset_file mii_tx.v     VERILOG PATH ../../hdl/verilog/mii_tx.v

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
add_interface_port s0 s_address   address   Input  4
add_interface_port s0 s_read      read      Input  1
add_interface_port s0 s_write     write     Input  1
add_interface_port s0 s_writedata writedata Input  32
add_interface_port s0 s_readdata  readdata  Output 32

add_interface m0 avalon start
set_interface_property m0 associatedClock zegar
set_interface_property m0 associatedReset reset
set_interface_property m0 addressUnits SYMBOLS
add_interface_port m0 m_address       address       Output 32
add_interface_port m0 m_read          read          Output 1
add_interface_port m0 m_waitrequest   waitrequest   Input  1
add_interface_port m0 m_readdata      readdata      Input  32
add_interface_port m0 m_readdatavalid readdatavalid Input  1

add_interface przerwanie interrupt end
set_interface_property przerwanie associatedAddressablePoint s0
set_interface_property przerwanie associatedClock zegar
set_interface_property przerwanie associatedReset reset
add_interface_port przerwanie irq irq Output 1

add_interface zegar_tx clock end
add_interface_port zegar_tx tx_clk clk Input 1
add_interface reset_tx reset end
set_interface_property reset_tx associatedClock zegar_tx
set_interface_property reset_tx synchronousEdges DEASSERT
add_interface_port reset_tx tx_rst reset Input 1

add_interface mii conduit end
set_interface_property mii associatedClock zegar_tx
add_interface_port mii txd   txd   Output 4
add_interface_port mii tx_en tx_en Output 1
