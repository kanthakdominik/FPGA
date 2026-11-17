PROJEKT := sta
include ../../../../plytka-deca/deca.mk

# Raporty Timing Analyzera do 14.05 i 14.06 (katalog raporty/).
raporty: $(SOF)
	$(QSTA) -t raporty.tcl $(PROJEKT)

.PHONY: raporty
