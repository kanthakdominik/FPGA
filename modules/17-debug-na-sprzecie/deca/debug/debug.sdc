# Ograniczenia projektu "debug" (moduł 17): trzy zegary, PLL 100 MHz, JTAG dla In-System Sources and Probes.

create_clock -name clk50 -period 20.000  [get_ports {MAX10_CLK1_50}]
create_clock -name clk10 -period 100.000 [get_ports {ADC_CLK_10}]
create_generated_clock -name clk100 -source [get_pins -compatibility_mode {*u_pll*|inclk[0]}] \
    -multiply_by 2 [get_pins -compatibility_mode {*u_pll*|clk[0]}]

# Zegar JTAG — port altera_reserved_tck powstaje, gdy projekt zawiera elementy debugowania (ISSP, Signal Tap).
if {[get_collection_size [get_ports -nowarn {altera_reserved_tck}]] > 0} {
    create_clock -name altera_reserved_tck -period 100.000 [get_ports {altera_reserved_tck}]
    set_clock_groups -asynchronous -group {altera_reserved_tck}
}
derive_clock_uncertainty

# Domeny łączą tylko synchronizatory: licznik Graya miernika częstotliwości (100 MHz i 10 MHz -> 50 MHz)
# i źródła ISSP z metastability enable. Grupy asynchroniczne + ograniczenie opóźnienia bitów Graya (15.07).
set_clock_groups -asynchronous -group {clk50} -group {clk100} -group {clk10}
set_net_delay -max 8.0 -from [get_registers {*u_f100|gray_m[*]}] -to [get_registers {*u_f100|sync1[*]}]
set_net_delay -max 8.0 -from [get_registers {*u_f10|gray_m[*]}]  -to [get_registers {*u_f10|sync1[*]}]

# Przyciski, przełączniki, diody i złącze: bez wymagań czasowych.
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*] GPIO0_D[*]}]
set_false_path -through [get_pins -compatibility_mode {*u_pll*|locked}]
