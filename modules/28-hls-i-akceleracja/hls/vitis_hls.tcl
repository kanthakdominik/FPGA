# Vitis HLS (28.04): symulacja C, synteza, kosymulacja RTL i eksport jądra jako IP. Nie uruchamiane w CI.
#   vitis_hls -f vitis_hls.tcl fir_blok          (albo: histogram_prosty, histogram_szybki, mnoz_prosto,
#                                                 mnoz_rownolegle, mlp)
# W nowszych wersjach (Vitis 2024.2+) to samo przez: vitis-run --mode hls --tcl vitis_hls.tcl
# Raport z liczbą taktów, II każdej pętli i zasobami: proj_<jądro>/sol1/syn/report/<jądro>_csynth.rpt
set jadro [lindex $argv 0]
if {$jadro eq ""} { set jadro fir_blok }
array set zrodla {
    fir_blok          {fir.cpp tb_fir.cpp}
    histogram_prosty  {histogram.cpp tb_histogram.cpp}
    histogram_szybki  {histogram.cpp tb_histogram.cpp}
    mnoz_prosto       {macierz.cpp tb_macierz.cpp}
    mnoz_rownolegle   {macierz.cpp tb_macierz.cpp}
    mlp               {mlp.cpp tb_mlp.cpp}
}
lassign $zrodla($jadro) zrodlo tb
set dane [file normalize ../../26-dsp-w-fpga/hdl/dane]
if {$jadro eq "mlp"} { set dane . }         ;# mlp_wektory.txt kopiowany do katalogu csim (add_files -tb)

open_project -reset proj_$jadro
set_top $jadro
add_files $zrodlo -cflags "-std=c++14"
add_files -tb $tb -cflags "-std=c++14 -I[pwd]"
add_files -tb [glob -nocomplain mlp_wektory.txt]
open_solution -reset sol1 -flow_target vivado
set_part {xc7z020clg400-1}
create_clock -period 10 -name default
csim_design -argv "$dane"
csynth_design
cosim_design -argv "$dane"
export_design -format ip_catalog
exit
