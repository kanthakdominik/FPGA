# Ograniczenia projektu "niosv" (moduł 27, 27.02): system Nios V na zegarze 50 MHz z oscylatora, bez PLL.
# Zegar JTAG (USB-Blaster II): moduł debugowania Nios V i JTAG UART tworzą port altera_reserved_tck.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
if {[get_collection_size [get_ports -nowarn {altera_reserved_tck}]] > 0} {
    create_clock -name altera_reserved_tck -period 100.000 [get_ports {altera_reserved_tck}]
    set_clock_groups -asynchronous -group {altera_reserved_tck}
}
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*]}]
set_false_path -to   [get_ports {LED[*]}]
