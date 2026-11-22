# Skrypt qsys-script (27.02, 27.03): system_niosv = źródło zegara 50 MHz + Nios V/m + pamięć wewnętrzna 64 KB
# + JTAG UART (konsola printf) + PIO 7 bitów (LED) + pwm_avl (27.03) z przerwaniem.
#   qsys-script --script=system.tcl --search-path="./,$"
#   qsys-generate system_niosv.qsys --synthesis=VERILOG --search-path="./,$"
# Połączenia jak w przykładach Altery dla Nios V/m (AN 988): instruction_manager -> pamięć i dm_agent,
# data_manager -> pamięć, dm_agent, timer_sw_agent i peryferia, przerwania -> platform_irq_rx.
# Nazwy parametrów rdzenia (resetSlave, resetOffset) jak w Quartus Prime 23.1/24.1 Standard/Lite; jeśli
# inna wersja ich nie zna, ustaw w GUI: Nios V/m -> Traps, Exceptions and Interrupts -> Reset Agent = ram.s1.
package require -exact qsys 16.1

create_system system_niosv
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
add_instance led altera_avalon_pio
set_instance_parameter_value led width 7
set_instance_parameter_value led direction Output
add_instance pwm pwm_avl

foreach k {cpu.clk ram.clk1 jtag_uart.clk led.clk pwm.zegar} {
    add_connection zegar.clk $k
}
foreach k {cpu.reset ram.reset1 jtag_uart.reset led.reset pwm.reset} {
    add_connection zegar.clk_reset $k
}

add_connection cpu.instruction_manager ram.s1
add_connection cpu.instruction_manager cpu.dm_agent
add_connection cpu.data_manager ram.s1
add_connection cpu.data_manager cpu.dm_agent
add_connection cpu.data_manager cpu.timer_sw_agent
add_connection cpu.data_manager jtag_uart.avalon_jtag_slave
add_connection cpu.data_manager led.s1
add_connection cpu.data_manager pwm.s0

# mapa adresów (bajty): RAM 0x0, rejestry rdzenia (debug, timer) przydziela narzędzie poniżej
set_connection_parameter_value cpu.instruction_manager/ram.s1 baseAddress 0x00000000
set_connection_parameter_value cpu.data_manager/ram.s1 baseAddress 0x00000000
set_connection_parameter_value cpu.data_manager/jtag_uart.avalon_jtag_slave baseAddress 0x00020000
set_connection_parameter_value cpu.data_manager/led.s1 baseAddress 0x00020010
set_connection_parameter_value cpu.data_manager/pwm.s0 baseAddress 0x00020020

add_connection cpu.platform_irq_rx jtag_uart.irq
set_connection_parameter_value cpu.platform_irq_rx/jtag_uart.irq irqNumber 0
add_connection cpu.platform_irq_rx pwm.przerwanie
set_connection_parameter_value cpu.platform_irq_rx/pwm.przerwanie irqNumber 1

set_instance_parameter_value cpu resetSlave ram.s1
set_instance_parameter_value cpu resetOffset 0

auto_assign_base_addresses cpu

add_interface clk clock sink
set_interface_property clk EXPORT_OF zegar.clk_in
add_interface reset reset sink
set_interface_property reset EXPORT_OF zegar.clk_in_reset
add_interface led conduit end
set_interface_property led EXPORT_OF led.external_connection
add_interface pwm conduit end
set_interface_property pwm EXPORT_OF pwm.wyjscie

save_system system_niosv.qsys
