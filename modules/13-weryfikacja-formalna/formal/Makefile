# Moduł 13 — weryfikacja formalna (SymbiYosys, Yosys, wtyczka GHDL; wszystko w OSS CAD Suite).
#   make               — wszystkie zadania i porównanie z oczekiwanymi wynikami (sprawdz.py)
#   make cnt10         — jeden plik .sby (cnt10, cnt10_vhdl, alu_hs, fifo_sync)
#   make rownowaznosc  — tylko skrypty równoważności Yosysa
#   make czysc         — usuwa katalogi robocze
SBY_PLIKI = cnt10 cnt10_vhdl alu_hs fifo_sync

wszystko:
	python3 sprawdz.py

$(SBY_PLIKI):
	python3 sprawdz.py $@

rownowaznosc:
	python3 sprawdz.py rownowaznosc_max rownowaznosc_synteza rownowaznosc_bug

czysc:
	rm -rf $(foreach f,$(SBY_PLIKI),$(f)_*/) *.log

.PHONY: wszystko $(SBY_PLIKI) rownowaznosc czysc
