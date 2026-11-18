PROJEKT := pamieci
include ../../../../plytka-deca/deca.mk

# Zestawienie pamięci po kompilacji (RAM Summary: bloki M9K, tryby, pliki inicjalizacji)
raporty: $(SOF)
	$(QSH) -t raporty.tcl $(PROJEKT)
	@cat raporty/pamieci.txt | head -40

.PHONY: raporty
