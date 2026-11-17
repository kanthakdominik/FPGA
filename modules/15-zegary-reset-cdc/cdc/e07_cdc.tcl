# 15.07 — przejścia między domenami w STA: bez ograniczeń, set_max_delay bez latencji zegarów
# (odpowiednik -datapath_only w Vivado) i pułapka: grupy zegarów razem z max_delay.
# clk_a 10 ns, clk_b 27,3 ns (bez wspólnej wielokrotności — zegary niezależne).
read_liberty $::env(LIB_DIR)/nangate45_slow.lib
read_liberty $::env(LIB_DIR)/nangate45_fast.lib
read_verilog build/cdc_dobry_net.v
link_design cdc_dobry
define_scene domyslna -liberty_min NangateOpenCellLibrary_fast -liberty_max NangateOpenCellLibrary_slow

proc sciezka {etykieta typ args} {
    puts "### $etykieta"
    report_checks -path_delay $typ -digits 3 -format full_clock_expanded {*}$args
    puts "### koniec"
}

create_clock -name clk_a -period 10   [get_ports clk_a]
create_clock -name clk_b -period 27.3 [get_ports clk_b]
set gray_a [get_cells u_fifo.wr_gray*_reg]
set sync_b [get_cells u_fifo.u_sync_wr.sync_r*_reg]

# 1. bez ograniczeń: STA szuka najbliższych zboczy dwóch niezależnych zegarów — relacja przypadkowa
sciezka bez_ograniczen_setup max -from $gray_a -to $sync_b
sciezka bez_ograniczen_hold  min -from $gray_a -to $sync_b

# 2. ograniczenie samej ścieżki danych (bez latencji zegarów) do okresu nadajnika — odpowiednik
#    set_max_delay -datapath_only w Vivado; hold między domenami wyłączony (bez sensu dla niezależnych zegarów)
set_max_delay 10 -ignore_clock_latency -from [get_clocks clk_a] -to [get_clocks clk_b]
set_false_path -hold -from [get_clocks clk_a] -to [get_clocks clk_b]
sciezka max_delay_setup max -from $gray_a -to $sync_b
sciezka max_delay_hold  min -from $gray_a -to $sync_b

# 3. dodanie grup zegarów: ścieżki znikają — set_clock_groups (false path) ma wyższy priorytet niż
#    set_max_delay, więc ograniczenie z punktu 2 przestaje działać (częsty błąd w plikach XDC)
set_clock_groups -asynchronous -group {clk_a} -group {clk_b}
sciezka grupy_i_max_delay max -from $gray_a -to $sync_b
