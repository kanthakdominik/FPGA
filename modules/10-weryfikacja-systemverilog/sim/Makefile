# Testbenche weryfikacyjne modułu 10 (SystemVerilog: klasy, losowanie, pokrycie, SVA) — Verilator 5.050+
# z rozwiązywaczem SMT (z3 albo cvc5) w PATH, np. z OSS CAD Suite.
#
#   make                       tb_env (środowisko warstwowe na trzech egzemplarzach alu_hs)
#   make TB=tb_random          wybrany testbench z katalogu tb/
#   make SEED=7                inne ziarno losowania (+verilator+seed+7)
#   make regresja              wszystkie testbenche z tb/, podsumowanie
#   make ziarna                tb_env z ziarnami 1..5
#   make pokrycie              tb_env z pomiarem pokrycia kodu i funkcjonalnego: raport, kod z adnotacjami,
#                              plik .info (lcov/genhtml)
#   make czysc
#
# Wynik testu: linia PASS w logu (build/<TB>.log); make kończy się błędem, gdy jej nie ma albo jest FAIL.

TB    ?= tb_env
SEED  ?= 1
TBDIR := $(abspath ../tb)
DUT   := $(abspath ../hdl/sv/alu_hs.sv)
BUILD := build
# kolejność: interfejs, pakiety (zależności przed użyciem), moduł asercji, testbench
ZRODLA := $(DUT) $(TBDIR)/alu_if.sv $(TBDIR)/alu_txn_pkg.sv $(TBDIR)/alu_cov_pkg.sv $(TBDIR)/alu_env_pkg.sv \
          $(TBDIR)/alu_sva.sv
TESTY := $(notdir $(basename $(wildcard $(TBDIR)/tb_*.sv)))
VFLAGS := --binary --timing --assert --coverage-user --timescale 1ns/1ps -Wno-fatal -Wno-lint -Wno-style

SPRAWDZ = grep -q '^PASS' $(1) && ! grep -q '^FAIL' $(1)

.PHONY: sim regresja ziarna pokrycie czysc

sim:
	@mkdir -p $(BUILD)
	verilator $(VFLAGS) --top-module $(TB) -Mdir $(BUILD)/obj_$(TB) $(ZRODLA) $(TBDIR)/$(TB).sv
	cd $(BUILD) && timeout 600 ./obj_$(TB)/V$(TB) +verilator+seed+$(SEED) | tee $(TB).log
	@$(call SPRAWDZ,$(BUILD)/$(TB).log)

regresja:
	@mkdir -p $(BUILD)
	@zal=0; niezal=0; \
	for t in $(TESTY); do \
	  if $(MAKE) --no-print-directory TB=$$t > $(BUILD)/regresja_$$t.txt 2>&1; \
	  then echo "PASS  $$t"; zal=$$((zal + 1)); \
	  else echo "FAIL  $$t  (log: $(BUILD)/regresja_$$t.txt)"; tail -20 $(BUILD)/regresja_$$t.txt; \
	       niezal=$$((niezal + 1)); fi; \
	done; \
	echo "zaliczone: $$zal, niezaliczone: $$niezal"; \
	test $$niezal -eq 0

ziarna:
	@mkdir -p $(BUILD)
	verilator $(VFLAGS) --top-module tb_env -Mdir $(BUILD)/obj_tb_env $(ZRODLA) $(TBDIR)/tb_env.sv > /dev/null
	@niezal=0; \
	for s in 1 2 3 4 5; do \
	  ( cd $(BUILD) && timeout 600 ./obj_tb_env/Vtb_env +verilator+seed+$$s > ziarno_$$s.log ); \
	  if $(call SPRAWDZ,$(BUILD)/ziarno_$$s.log); then echo "PASS  ziarno $$s"; \
	  else echo "FAIL  ziarno $$s"; cat $(BUILD)/ziarno_$$s.log; niezal=$$((niezal + 1)); fi; \
	done; \
	test $$niezal -eq 0

pokrycie:
	@mkdir -p $(BUILD)/pokrycie
	verilator $(VFLAGS) --coverage --top-module tb_env -Mdir $(BUILD)/obj_cov $(ZRODLA) $(TBDIR)/tb_env.sv > /dev/null
	cd $(BUILD)/pokrycie && timeout 600 ../obj_cov/Vtb_env +verilator+seed+$(SEED) | tee tb_env.log
	@$(call SPRAWDZ,$(BUILD)/pokrycie/tb_env.log)
	cd $(BUILD)/pokrycie && verilator_coverage --report summary coverage.dat | tee podsumowanie.txt
	cd $(BUILD)/pokrycie && verilator_coverage --annotate adnotacje --annotate-min 1 coverage.dat > /dev/null
	@echo "Niepokryte (%) i częściowo pokryte (~) wiersze układu alu_hs:"
	@grep -E '^ *[%~]' $(BUILD)/pokrycie/adnotacje/alu_hs.sv || echo "  brak"
	cd $(BUILD)/pokrycie && verilator_coverage --write-info pokrycie.info coverage.dat

czysc:
	rm -rf $(BUILD)
