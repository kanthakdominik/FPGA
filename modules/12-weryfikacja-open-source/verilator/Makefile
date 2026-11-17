# fir8 w Verilatorze z testbenchem w C++ oraz porównanie szybkości symulatorów na tym samym układzie.
#
#   make                 kompilacja i test (2 mln próbek)
#   make N=200000 BUG=1  inna liczba próbek, układ z błędem (oczekiwane FAIL)
#   make trace           przebiegi do build/fir8.fst (pierwsze 10 000 taktów)
#   make porownanie      ta sama liczba próbek w Icarusie, Verilatorze (testbench SV) i Verilatorze (C++)
#   make czysc

.DEFAULT_GOAL := test

N     ?= 2000000
BUG   ?= 0
NCMP  ?= 200000
HDL   := $(abspath ../hdl)
BUILD := build
VFLAGS := --cc --exe --build -j 0 -O3 --x-assign fast --x-initial fast --trace-fst -Wno-fatal -Wno-lint \
          -Wno-style -CFLAGS "-O2 -std=c++20" -GBUG=$(BUG)

.PHONY: test trace porownanie czysc

$(BUILD)/bug$(BUG)/Vfir8: tb_fir8.cpp $(HDL)/sv/fir8.sv
	@mkdir -p $(BUILD)
	verilator $(VFLAGS) --top-module fir8 -Mdir $(BUILD)/bug$(BUG) $(HDL)/sv/fir8.sv tb_fir8.cpp > $(BUILD)/kompilacja.log

test: $(BUILD)/bug$(BUG)/Vfir8
	cd $(BUILD) && ./bug$(BUG)/Vfir8 +n=$(N) | tee wynik.log
	@grep -q '^PASS' $(BUILD)/wynik.log

trace: $(BUILD)/bug$(BUG)/Vfir8
	cd $(BUILD) && ./bug$(BUG)/Vfir8 +n=5000 +trace
	@ls -l $(BUILD)/fir8.fst

# czas całego programu (z uruchomieniem) dla NCMP próbek losowych; takty ≈ 1,25 × NCMP
porownanie: $(BUILD)/bug0/Vfir8
	@mkdir -p $(BUILD)/cmp
	iverilog -g2012 -o $(BUILD)/cmp/icarus.vvp $(HDL)/verilog/fir8.v $(HDL)/verilog/tb_fir8.v
	verilator --binary -j 0 -O3 --timing -Wno-fatal -Wno-lint -Wno-style --top-module tb_fir8 \
	  -Mdir $(BUILD)/cmp/obj_sv $(HDL)/sv/fir8.sv $(HDL)/sv/tb_fir8.sv > /dev/null
	@printf '%-34s %10s\n' "symulator / testbench" "czas [s]"
	@s=$$(date +%s.%N); vvp -n $(BUILD)/cmp/icarus.vvp +N=$(NCMP) > $(BUILD)/cmp/icarus.log; e=$$(date +%s.%N); \
	  grep -q '^PASS' $(BUILD)/cmp/icarus.log && printf '%-34s %10.2f\n' "Icarus, testbench Verilog" $$(echo "$$e - $$s" | bc)
	@s=$$(date +%s.%N); $(BUILD)/cmp/obj_sv/Vtb_fir8 +N=$(NCMP) > $(BUILD)/cmp/sv.log; e=$$(date +%s.%N); \
	  grep -q '^PASS' $(BUILD)/cmp/sv.log && printf '%-34s %10.2f\n' "Verilator, testbench SV (--timing)" $$(echo "$$e - $$s" | bc)
	@s=$$(date +%s.%N); $(BUILD)/bug0/Vfir8 +n=$(NCMP) > $(BUILD)/cmp/cpp.log; e=$$(date +%s.%N); \
	  grep -q '^PASS' $(BUILD)/cmp/cpp.log && printf '%-34s %10.2f\n' "Verilator, testbench C++" $$(echo "$$e - $$s" | bc)

czysc:
	rm -rf $(BUILD)
