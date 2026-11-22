PROJEKT := udp_ddr3
include ../../../../plytka-deca/deca.mk

QSYS_SCRIPT   ?= qsys-script
QSYS_GENERATE ?= qsys-generate

# 1. system Platform Designer ze skryptu (przed pierwszym "make")
system: system_udp/synthesis/system_udp.qip
system_udp/synthesis/system_udp.qip: system.tcl udp_dma_hw.tcl ../../hdl/verilog/udp_dma.v
	$(QSYS_SCRIPT) --script=system.tcl --search-path="./,$$"
	$(QSYS_GENERATE) system_udp.qsys --synthesis=VERILOG --search-path="./,$$"

# 2. make, make sram — sprzęt (deca.mk); 3. oprogramowanie w Nios V Command Shell:
bsp:
	niosv-bsp -c -t=hal --sopcinfo=system_udp.sopcinfo software/bsp/settings.bsp

app:
	niosv-app -a=software/app -b=software/bsp -s=software/src
	cmake -S software/app -B software/app/build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
	make -C software/app/build

pobierz:
	niosv-download -g software/app/build/app.elf
	juart-terminal

# test składni programu na komputerze (bez BSP): system.h zastąpiony definicją adresu
skladnia:
	printf '#define UDP_BASE 0x20040\n' > /tmp/system.h
	gcc -std=c11 -Wall -Wextra -Werror -fsyntax-only -I/tmp -Isoftware/src software/src/*.c

.PHONY: system bsp app pobierz skladnia
