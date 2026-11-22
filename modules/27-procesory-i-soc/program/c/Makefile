# Program w C dla rv_soc (27.03, 27.07): kompilacja gcc RISC-V (pakiet gcc-riscv64-unknown-elf albo dowolny
# riscv*-elf-gcc), obraz do pamięci (prog_c.hex) i symulacja w Icarusie.
#   make            — prog_c.elf, prog_c.hex, rozmiar i początek deasemblacji
#   make sym        — symulacja sim_c.v z rv_soc
CROSS  ?= riscv64-unknown-elf-
CFLAGS := -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -nostartfiles -Wall -Wextra \
          -fno-tree-loop-distribute-patterns          # bez tego pętla w memset staje się wywołaniem memset
HDL    := ../../hdl/verilog
RTL    := $(addprefix $(HDL)/,rv_alu.v rv_dekoder.v rv_rejestry.v rv_wyrownanie.v rv_potok.v pwm_avl.v rv_soc.v)

all: prog_c.hex

prog_c.elf: crt0.S main.c pwm.c wsparcie.c pwm.h link.ld
	$(CROSS)gcc $(CFLAGS) -T link.ld -Wl,--no-relax -Wl,--no-warn-rwx-segments -o $@ crt0.S main.c pwm.c wsparcie.c
	$(CROSS)size $@
	$(CROSS)objdump -d $@ | head -40

prog_c.hex: prog_c.elf
	$(CROSS)objcopy -O binary $< prog_c.bin
	python3 ../rvasm.py --bin2hex prog_c.bin $@

sym: prog_c.hex
	iverilog -g2005 -o sim_c.vvp sim_c.v $(RTL)
	vvp -n sim_c.vvp

clean:
	rm -f prog_c.elf prog_c.bin prog_c.hex sim_c.vvp

.PHONY: all sym clean
