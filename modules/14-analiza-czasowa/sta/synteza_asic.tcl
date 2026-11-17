# Synteza sta_demo do komórek biblioteki NanGate 45 nm (Liberty) — netlista dla OpenSTA.
# Uruchomienie: LIB=<plik .lib> yosys -c synteza_asic.tcl   (robi to sprawdz_sta.py)
set lib $::env(LIB)
yosys read_verilog ../hdl/verilog/dzielnik_mc.v ../hdl/verilog/spi_master.v sta_demo.v
yosys synth -top sta_demo -flatten
# przerzutniki dostają nazwy rejestrów, które sterują (np. u_dziel.a_r[3]_reg) — do wyboru ścieżek w SDC
yosys rename -wire -suffix _reg t:*DFF*
yosys dfflibmap -liberty $lib
yosys abc -liberty $lib
yosys opt_clean -purge
yosys hilomap -hicell LOGIC1_X1 Z -locell LOGIC0_X1 Z
yosys setundef -zero
yosys splitnets -ports
yosys autoname
yosys opt_clean -purge
yosys tee -o build/synteza_stat.txt stat -liberty $lib
yosys write_verilog -noattr -noexpr -nohex -nodec build/sta_demo_net.v
