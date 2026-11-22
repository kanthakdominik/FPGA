PROJEKT := obrazy
include ../../../../plytka-deca/deca.mk

QSYS_SCRIPT   ?= qsys-script
QSYS_GENERATE ?= qsys-generate
QCPF          ?= quartus_cpf

# 1. rdzeń Dual Configuration (raz)
system: system_dual/synthesis/system_dual.qip
system_dual/synthesis/system_dual.qip: system.tcl
	$(QSYS_SCRIPT) --script=system.tcl
	$(QSYS_GENERATE) system_dual.qsys --synthesis=VERILOG

# 2. dwa obrazy z tego samego źródła (różny parametr OBRAZ)
obraz0 obraz1: obraz%:
	rm -f .projekt-*
	OBRAZ=$* $(QSH) -t utworz_projekt.tcl $(JEZYK) $(UKLAD)
	touch .projekt-$(JEZYK)
	$(QSH) --flow compile $(PROJEKT)
	cp $(SOF) obraz$*.sof

# 3. .pof z obu obrazów: ustawienia konwersji zapisane w GUI jako obrazy.cof (README.md)
pof: obrazy.cof
	$(QCPF) -c obrazy.cof

.PHONY: system obraz0 obraz1 pof
