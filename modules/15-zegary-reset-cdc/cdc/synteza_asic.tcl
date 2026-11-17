# Synteza cdc_dobry do komórek NanGate 45 nm — netlista dla OpenSTA (15.07), jak w module 14.
# Uruchomienie: LIB=<plik .lib> yosys -c synteza_asic.tcl   (robi to sprawdz_sta_cdc.py)
set lib $::env(LIB)
set hdl ../hdl/verilog
yosys read_verilog $hdl/sync_bit.v $hdl/sync_pulse.v $hdl/cdc_handshake.v $hdl/gray_cdc.v $hdl/async_fifo.v cdc_przyklady.v
yosys synth -top cdc_dobry -flatten
yosys rename -wire -suffix _reg t:*DFF*
yosys dfflibmap -liberty $lib
yosys abc -liberty $lib
yosys opt_clean -purge
yosys hilomap -hicell LOGIC1_X1 Z -locell LOGIC0_X1 Z
yosys setundef -zero
yosys splitnets -ports
yosys autoname
yosys opt_clean -purge
yosys write_verilog -noattr -noexpr -nohex -nodec build/cdc_dobry_net.v
