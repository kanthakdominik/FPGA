PROJEKT := niosv
include ../../../../plytka-deca/deca.mk

QSYS_SCRIPT   ?= qsys-script
QSYS_GENERATE ?= qsys-generate
STEROWNIK     := ../../../program/c

# 1. system Platform Designer ze skryptu (przed pierwszym "make")
system: system_niosv/synthesis/system_niosv.qip
system_niosv/synthesis/system_niosv.qip: system.tcl pwm_avl_hw.tcl ../../hdl/verilog/pwm_avl.v
	$(QSYS_SCRIPT) --script=system.tcl --search-path="./,$$"
	$(QSYS_GENERATE) system_niosv.qsys --synthesis=VERILOG --search-path="./,$$"

# 2. make, make sram — sprzęt (deca.mk); 3. oprogramowanie w Nios V Command Shell:
bsp:
	niosv-bsp -c -t=hal --sopcinfo=system_niosv.sopcinfo software/bsp/settings.bsp

app:
	cp $(STEROWNIK)/pwm.h $(STEROWNIK)/pwm.c software/src/
	niosv-app -a=software/app -b=software/bsp -s=software/src
	cmake -S software/app -B software/app/build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
	make -C software/app/build

pobierz:
	niosv-download -g software/app/build/app.elf
	juart-terminal

.PHONY: system bsp app pobierz
