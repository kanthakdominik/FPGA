# 14.02 — ta sama ścieżka w trzech narożnikach biblioteki: SS (wolny), TT, FF (szybki).
read_liberty $::env(LIB_DIR)/nangate45_slow.lib
read_liberty $::env(LIB_DIR)/nangate45_typ.lib
read_liberty $::env(LIB_DIR)/nangate45_fast.lib
read_verilog build/sta_demo_net.v
link_design sta_demo
define_scene ss -liberty NangateOpenCellLibrary_slow
define_scene tt -liberty NangateOpenCellLibrary
define_scene ff -liberty NangateOpenCellLibrary_fast
source wspolne.tcl
create_clock -name clk -period 8 [get_ports clk]
set a_r [rejestry u_dziel.a_r]
set q_r [rejestry u_dziel.q]
foreach s {ss tt ff} {
    sciezka dzielnik_$s max -scenes $s -from $a_r -to $q_r
}
