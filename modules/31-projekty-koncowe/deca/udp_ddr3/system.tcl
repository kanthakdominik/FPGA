# Skrypt qsys-script (31.04): system_udp = zegar 50 MHz + Nios V/m + pamięć wewnętrzna 64 KB (program i bufory)
# + JTAG UART (printf) + udp_dma (31.04) z przerwaniem; master udp_dma czyta pamięć przez interconnect.
#   qsys-script --script=system.tcl --search-path="./,$"
#   qsys-generate system_udp.qsys --synthesis=VERILOG --search-path="./,$"
# Bufory w DDR3: dodaj w GUI kontroler „DDR3 SDRAM Controller with UniPHY” z ustawieniami z modułu 23 (README.md
# w tym katalogu), połącz jego avl z cpu.data_manager i udp.m0, a zegar systemu weź z afi_half_clk kontrolera.
# Nazwy parametrów rdzeni jak w Quartus Prime 23.1/24.1 Lite (zob. modules/27-procesory-i-soc/deca/niosv/system.tcl).
package require -exact qsys 16.1

create_system system_udp
set_project_property DEVICE_FAMILY "MAX 10"
set_project_property DEVICE 10M50DAF484C6GES

add_instance zegar clock_source
set_instance_parameter_value zegar clockFrequency 50000000
set_instance_parameter_value zegar clockFrequencyKnown true
set_instance_parameter_value zegar resetSynchronousEdges DEASSERT

add_instance cpu intel_niosv_m
add_instance ram altera_avalon_onchip_memory2
set_instance_parameter_value ram memorySize 65536
set_instance_parameter_value ram dataWidth 32
add_instance jtag_uart altera_avalon_jtag_uart
add_instance udp udp_dma

foreach k {cpu.clk ram.clk1 jtag_uart.clk udp.zegar} { add_connection zegar.clk $k }
foreach k {cpu.reset ram.reset1 jtag_uart.reset udp.reset} { add_connection zegar.clk_reset $k }

add_connection cpu.instruction_manager ram.s1
add_connection cpu.instruction_manager cpu.dm_agent
add_connection cpu.data_manager ram.s1
add_connection cpu.data_manager cpu.dm_agent
add_connection cpu.data_manager cpu.timer_sw_agent
add_connection cpu.data_manager jtag_uart.avalon_jtag_slave
add_connection cpu.data_manager udp.s0
add_connection udp.m0 ram.s1

set_connection_parameter_value cpu.instruction_manager/ram.s1 baseAddress 0x00000000
set_connection_parameter_value cpu.data_manager/ram.s1 baseAddress 0x00000000
set_connection_parameter_value udp.m0/ram.s1 baseAddress 0x00000000
set_connection_parameter_value cpu.data_manager/jtag_uart.avalon_jtag_slave baseAddress 0x00020000
set_connection_parameter_value cpu.data_manager/udp.s0 baseAddress 0x00020040

add_connection cpu.platform_irq_rx jtag_uart.irq
set_connection_parameter_value cpu.platform_irq_rx/jtag_uart.irq irqNumber 0
add_connection cpu.platform_irq_rx udp.przerwanie
set_connection_parameter_value cpu.platform_irq_rx/udp.przerwanie irqNumber 1

set_instance_parameter_value cpu resetSlave ram.s1
set_instance_parameter_value cpu resetOffset 0
auto_assign_base_addresses cpu

add_interface clk clock sink
set_interface_property clk EXPORT_OF zegar.clk_in
add_interface reset reset sink
set_interface_property reset EXPORT_OF zegar.clk_in_reset
add_interface tx_clk clock sink
set_interface_property tx_clk EXPORT_OF udp.zegar_tx
add_interface tx_reset reset sink
set_interface_property tx_reset EXPORT_OF udp.reset_tx
add_interface mii conduit end
set_interface_property mii EXPORT_OF udp.mii

save_system system_udp.qsys
