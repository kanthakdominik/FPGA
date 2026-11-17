PROJEKT := debug
include ../../../../plytka-deca/deca.mk

QSTP ?= quartus_stp

# Odczyt miernika częstotliwości przez JTAG (17.01, 17.03)
czestotliwosci:
	$(QSTP) -t czestotliwosci.tcl

# mini_ila: zbocze naciśnięcia KEY[1], 64 próbki przed nim; wynik w raporty/ila.vcd (17.02)
ila:
	$(QSTP) -t ila_odczyt.tcl 0x8000 0x8000 1 64

.PHONY: czestotliwosci ila
