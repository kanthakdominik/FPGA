# 03 — Przepływ projektowy od RTL do bitstreamu

> **Część I** · **Oznaczenia:** 🟢🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 10 h · **Status:** 🔲 szkielet

## Po co ten moduł

Każdy etap przepływu projektowego — synteza, rozmieszczanie, trasowanie, analiza czasowa i generowanie pliku konfiguracyjnego — z tym, co trzeba sprawdzić w raportach. Do tego praca skryptowa, bez której nie da się prowadzić projektu w zespole.

## Wymagane wcześniej

[00 — Środowisko pracy i pierwszy projekt](../00-srodowisko-pracy/README.md), [02 — Architektura układów FPGA](../02-architektura-fpga/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 03.01 | [Etapy: opracowanie, synteza, mapowanie, rozmieszczanie, trasowanie, bitstream](03.01-etapy-opracowanie-synteza-mapowanie.md) | — | — | 🔲 |
| 03.02 | [Synteza: co robi syntezator i jak czytać jego raport](03.02-synteza-co-robi-syntezator-i-jak-czytac-jego.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 03.03 | [Ograniczenia: piny, standardy I/O i zegary (QSF, SDC, XDC, PCF)](03.03-ograniczenia-piny-standardy-i-o-i-zegary-qsf.md) | — | 🛠️ | 🔲 |
| 03.04 | [Raporty: zasoby, czasy i ostrzeżenia, których nie wolno ignorować](03.04-raporty-zasoby-czasy-i-ostrzezenia-ktorych-nie.md) | — | 🛠️ | 🔲 |
| 03.05 | [Praca skryptowa: Tcl, tryb wsadowy i Makefile](03.05-praca-skryptowa-tcl-tryb-wsadowy-i-makefile.md) | — | 🛠️ | 🔲 |
| 03.06 | [Otwarty przepływ: Yosys, nextpnr i narzędzia konfiguracyjne](03.06-otwarty-przeplyw-yosys-nextpnr-i-narzedzia.md) | — | — | 🔲 |
| 03.07 | [Programowanie układu: JTAG, pliki .sof i .pof, pamięć konfiguracyjna](03.07-programowanie-ukladu-jtag-pliki-sof-i-pof.md) | — | 🛠️ | 🔲 |

## Po tym module potrafisz

- wymienić etapy przepływu i powiedzieć, co powstaje na każdym z nich,
- przypisać piny i standardy I/O oraz zdefiniować zegar w plikach QSF i SDC,
- odczytać raport zasobów, raport czasowy i ostrzeżenia syntezy, które naprawdę mają znaczenie,
- uruchomić kompilację z linii poleceń skryptem Tcl lub Makefile,
- przejść ten sam projekt otwartym przepływem Yosys + nextpnr.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 03.01 Etapy: opracowanie, synteza, mapowanie, rozmieszczanie, trasowanie, bitstream
- [ ] 03.02 Synteza: co robi syntezator i jak czytać jego raport
- [ ] 03.03 Ograniczenia: piny, standardy I/O i zegary (QSF, SDC, XDC, PCF)
- [ ] 03.04 Raporty: zasoby, czasy i ostrzeżenia, których nie wolno ignorować
- [ ] 03.05 Praca skryptowa: Tcl, tryb wsadowy i Makefile
- [ ] 03.06 Otwarty przepływ: Yosys, nextpnr i narzędzia konfiguracyjne
- [ ] 03.07 Programowanie układu: JTAG, pliki .sof i .pof, pamięć konfiguracyjna
