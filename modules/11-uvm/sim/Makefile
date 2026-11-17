# Środowisko UVM modułu 11 — Verilator 5.050+ z rozwiązywaczem SMT (z3) i biblioteką UVM (IEEE 1800.2,
# Accellera uvm-core 2020.3.1). Ścieżka do katalogu src biblioteki: UVM_HOME.
#
#   make UVM_HOME=…/uvm-core/src                 build + smoke_test
#   make TEST=rand_test                           wybrany test (+UVM_TESTNAME)
#   make TEST=rand_test BUG=1 SEED=7              układ z błędem, inne ziarno
#   make TEST=rand_test ARGS=+N_ITEMS=200        argumenty programu (z UVM_NO_DPI nie działają +UVM_VERBOSITY itp.)
#   make regresja                                 wszystkie testy na układzie poprawnym
#   make bledy                                    układy z błędami: oczekiwane FAIL tam, gdzie test ma wykryć błąd
#   make czysc
#
# Kompilacja biblioteki UVM trwa kilka minut; jeden program na wartość BUG obsługuje wszystkie testy.

UVM_HOME ?=
TEST     ?= smoke_test
BUG      ?= 0
SEED     ?= 1
ARGS     ?=
TBDIR    := $(abspath ../tb)
DUT      := $(abspath ../hdl/sv/axil_regs.sv)
BUILD    := build
ZRODLA   := $(UVM_HOME)/uvm_pkg.sv $(DUT) $(TBDIR)/axil_if.sv $(TBDIR)/axil_pkg.sv $(TBDIR)/regs_ral_pkg.sv \
            $(TBDIR)/env_pkg.sv $(TBDIR)/tests_pkg.sv $(TBDIR)/tb_uvm.sv
VFLAGS   := --binary -j 0 --timing --assert --timescale 1ns/1ps -Wno-fatal -Wno-lint -Wno-style \
            +define+UVM_NO_DPI +define+UVM_REPORT_DISABLE_FILE_LINE +incdir+$(UVM_HOME) +incdir+$(TBDIR)
TESTY    := smoke_test phases_test rand_test reg_reset_test reg_bitbash_test reg_access_test full_test

# test:BUG:oczekiwany wynik — czy test wykrywa (FAIL), czy nie (PASS) wstrzyknięty błąd
OCZEKIWANE := rand_test:1:FAIL reg_bitbash_test:1:PASS rand_test:2:FAIL reg_access_test:2:FAIL reg_reset_test:2:PASS

ifneq ($(filter-out czysc,$(or $(MAKECMDGOALS),sim)),)
  ifeq ($(wildcard $(UVM_HOME)/uvm_pkg.sv),)
    $(error Ustaw UVM_HOME na katalog src biblioteki UVM (z plikiem uvm_pkg.sv))
  endif
endif

SPRAWDZ = grep -q '^PASS' $(1) && ! grep -q '^FAIL' $(1)

.PHONY: sim program regresja bledy czysc

$(BUILD)/obj_bug%/Vtb_uvm: $(ZRODLA)
	@mkdir -p $(BUILD)
	verilator $(VFLAGS) -GBUG=$* --top-module tb_uvm -Mdir $(BUILD)/obj_bug$* $(ZRODLA) > $(BUILD)/kompilacja_bug$*.log 2>&1 \
	  || { tail -40 $(BUILD)/kompilacja_bug$*.log; exit 1; }

program: $(BUILD)/obj_bug$(BUG)/Vtb_uvm

sim: program
	cd $(BUILD) && timeout 300 stdbuf -oL ./obj_bug$(BUG)/Vtb_uvm +UVM_TESTNAME=$(TEST) +verilator+seed+$(SEED) $(ARGS) \
	  | tee $(TEST)_bug$(BUG).log
	@$(call SPRAWDZ,$(BUILD)/$(TEST)_bug$(BUG).log)

regresja: $(BUILD)/obj_bug0/Vtb_uvm
	@zal=0; niezal=0; \
	for t in $(TESTY); do \
	  ( cd $(BUILD) && timeout 300 stdbuf -oL ./obj_bug0/Vtb_uvm +UVM_TESTNAME=$$t +verilator+seed+$(SEED) > $${t}_bug0.log 2>&1 ); \
	  info="$$(grep -oh 'sprawdzonych transakcji: [0-9]*\|pokrycie funkcjonalne: [0-9.]* %\|finish at [^;]*; walltime [0-9.]* s' \
	         $(BUILD)/$${t}_bug0.log | paste -sd ',' -)"; \
	  if $(call SPRAWDZ,$(BUILD)/$${t}_bug0.log); then echo "PASS  $$t  ($$info)"; zal=$$((zal + 1)); \
	  else echo "FAIL  $$t"; grep -E 'UVM_(ERROR|FATAL) |naruszen|^FAIL' $(BUILD)/$${t}_bug0.log | head -20; \
	       niezal=$$((niezal + 1)); fi; \
	done; \
	echo "zaliczone: $$zal, niezaliczone: $$niezal"; \
	test $$niezal -eq 0

bledy: $(BUILD)/obj_bug1/Vtb_uvm $(BUILD)/obj_bug2/Vtb_uvm
	@zle=0; \
	for p in $(OCZEKIWANE); do \
	  t=$${p%%:*}; r=$${p#*:}; b=$${r%%:*}; o=$${r#*:}; \
	  ( cd $(BUILD) && timeout 300 stdbuf -oL ./obj_bug$$b/Vtb_uvm +UVM_TESTNAME=$$t +verilator+seed+$(SEED) > $${t}_bug$$b.log 2>&1 ); \
	  if $(call SPRAWDZ,$(BUILD)/$${t}_bug$$b.log); then w=PASS; else w=FAIL; fi; \
	  n=$$(grep -c 'UVM_ERROR @' $(BUILD)/$${t}_bug$$b.log); \
	  if [ $$w = $$o ]; then echo "OK    $$t BUG=$$b: $$w (oczekiwano $$o), UVM_ERROR: $$n"; \
	  else echo "ZLE   $$t BUG=$$b: $$w (oczekiwano $$o)"; zle=$$((zle + 1)); fi; \
	  grep -m 2 'UVM_ERROR @' $(BUILD)/$${t}_bug$$b.log | sed 's/^/        /'; \
	done; \
	test $$zle -eq 0

czysc:
	rm -rf $(BUILD)
