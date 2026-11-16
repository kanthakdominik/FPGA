# Symulacja testbenchy modułu 09 z linii poleceń: jeden test, przebiegi, regresja, symulacja po syntezie.
#
#   make                                  tb_mavg4 w Verilogu (Icarus)
#   make TB=tb_mavg4_file JEZYK=vhdl      wybrany testbench i język: verilog | vhdl | sv
#   make FALE=1 [JEZYK=…]                 zapis przebiegów do build/: <TB>.vcd (Icarus, tylko testbenche z $dumpfile),
#                                         <TB>.ghw (GHDL, dowolny testbench), <TB>.fst (Verilator, kod w `ifdef FALE)
#   make regresja                         wszystkie testbenche modułu we wszystkich językach, podsumowanie
#   make po_syntezie                      synteza mavg4.v Yosysem do netlisty bramek i te same testbenche na netliście
#   make czysc
#
# Wynik testu: linia PASS w logu (build/<TB>.log); make kończy się błędem, gdy jej nie ma albo jest FAIL.

TB    ?= tb_mavg4
JEZYK ?= verilog
FALE  ?=

HDL   := $(abspath ../hdl)
BUILD := build
DANE  := $(filter-out %.py,$(wildcard $(HDL)/dane/*))
RTL_V := $(filter-out $(HDL)/verilog/tb_%,$(wildcard $(HDL)/verilog/*.v))
RTL_SV:= $(filter-out $(HDL)/sv/tb_%,$(wildcard $(HDL)/sv/*.sv))
VHDL  := $(wildcard $(HDL)/vhdl/*.vhd)
TESTY := $(notdir $(basename $(wildcard $(HDL)/verilog/tb_*.v)))

# sprawdzenie logu: jest PASS i nie ma FAIL
SPRAWDZ = grep -q '^PASS' $(BUILD)/$(1).log && ! grep -q '^FAIL' $(BUILD)/$(1).log

.PHONY: sim verilog vhdl sv regresja po_syntezie czysc katalog

sim: $(JEZYK)

katalog:
	@mkdir -p $(BUILD)
	@cp $(DANE) $(BUILD)/

verilog: katalog
	iverilog -g2005 -Wall -s $(TB) -o $(BUILD)/$(TB).vvp $(RTL_V) $(HDL)/verilog/$(TB).v
	cd $(BUILD) && vvp -n $(TB).vvp $(if $(FALE),+fale) | tee $(TB).log
	@$(call SPRAWDZ,$(TB))

vhdl: katalog
	cd $(BUILD) && ghdl -i --std=08 $(VHDL) && ghdl -m --std=08 $(TB) && \
	  ghdl -r --std=08 $(TB) --assert-level=error $(if $(FALE),--wave=$(TB).ghw) | tee $(TB).log
	@$(call SPRAWDZ,$(TB))

sv: katalog
	verilator --binary --timing --timescale 1ns/1ps -Wno-fatal -Wno-lint -Wno-style \
	  $(if $(FALE),--trace-fst -DFALE) --top-module $(TB) -Mdir $(BUILD)/obj_$(TB) $(RTL_SV) $(HDL)/sv/$(TB).sv
	cd $(BUILD) && ./obj_$(TB)/V$(TB) | tee $(TB).log
	@$(call SPRAWDZ,$(TB))

regresja: katalog
	@zal=0; niezal=0; \
	for j in verilog vhdl sv; do \
	  for t in $(TESTY); do \
	    if $(MAKE) --no-print-directory TB=$$t JEZYK=$$j > $(BUILD)/regresja_$${j}_$$t.txt 2>&1; \
	    then echo "PASS  $$j  $$t"; zal=$$((zal + 1)); \
	    else echo "FAIL  $$j  $$t  (log: $(BUILD)/regresja_$${j}_$$t.txt)"; niezal=$$((niezal + 1)); fi; \
	  done; \
	done; \
	echo "zaliczone: $$zal, niezaliczone: $$niezal"; \
	test $$niezal -eq 0

# Netlista po syntezie: komórki ogólne Yosysa zapisane jako Verilog (przypisania i bloki always),
# bez opóźnień — sprawdza funkcję po syntezie, nie czasy. Testbenche RTL bez zmian, inny układ pod nimi.
po_syntezie: katalog
	yosys -q -p "read_verilog $(HDL)/verilog/mavg4.v; synth -flatten -top mavg4; opt_clean; \
	  write_verilog -noattr $(BUILD)/mavg4_netlista.v"
	@grep -c "always" $(BUILD)/mavg4_netlista.v | xargs echo "bloki always w netliście:"
	for t in tb_mavg4 tb_mavg4_file tb_mavg4_basic; do \
	  iverilog -g2005 -s $$t -o $(BUILD)/$$t.net.vvp $(BUILD)/mavg4_netlista.v $(HDL)/verilog/$$t.v && \
	  ( cd $(BUILD) && vvp -n $$t.net.vvp | tee $$t.net.log ) && \
	  grep -q '^PASS' $(BUILD)/$$t.net.log && ! grep -q '^FAIL' $(BUILD)/$$t.net.log || exit 1; \
	done

czysc:
	rm -rf $(BUILD) work-obj08.cf
