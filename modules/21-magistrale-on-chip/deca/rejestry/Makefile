PROJEKT := rejestry
include ../../../../plytka-deca/deca.mk

QSYS_SCRIPT   ?= qsys-script
QSYS_GENERATE ?= qsys-generate

# system Platform Designer ze skryptu (przed pierwszym "make")
system: system_rej/synthesis/system_rej.qip
system_rej/synthesis/system_rej.qip: system.tcl avmm_rejestry_hw.tcl ../../hdl/verilog/avmm_rejestry.v ../../hdl/verilog/rejestry_rdzen.v
	$(QSYS_SCRIPT) --script=system.tcl --search-path="./,$$"
	$(QSYS_GENERATE) system_rej.qsys --synthesis=VERILOG --search-path="./,$$"

konsola:
	system-console --script=konsola.tcl

.PHONY: system konsola
