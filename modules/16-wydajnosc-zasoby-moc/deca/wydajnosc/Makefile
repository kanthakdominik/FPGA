PROJEKT := wydajnosc
include ../../../../plytka-deca/deca.mk

QPOW ?= quartus_pow

# Przegląd ziaren Fittera (16.04): raporty/ziarna.txt
ziarna: $(SOF)
	$(QSH) -t ziarna.tcl $(PROJEKT) 1 2 3 4 5

# Analiza mocy (16.06): szacowanie bez wektorów, domyślna aktywność 12,5 %; wynik w output_files/*.pow.*
# i plik do Early Power Estimatora w raporty/epe.csv
moc: $(SOF)
	mkdir -p raporty
	$(QPOW) $(PROJEKT) --default_toggle_rate=12.5% --output_epe=raporty/epe.csv
	@grep -E "Total Thermal Power|Core Dynamic|Core Static|I/O Thermal" output_files/$(PROJEKT).pow.summary || true

.PHONY: ziarna moc
