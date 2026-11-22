# 00 — Środowisko pracy i pierwszy projekt

> **Część I** · **Oznaczenia:** 🟢🛠️ · **Ścieżki:** RTL, weryfikacja, DECA · **Szacowany czas:** ok. 8 h

## Po co ten moduł

Instalujesz narzędzia, przechodzisz cały przepływ od pliku HDL do świecącej diody na płytce DECA i ustawiasz repozytorium projektu tak, jak robi się to w pracy. Po tym module każdy następny przykład uruchomisz bez walki z narzędziami.

## Wymagane wcześniej

Nic — od tego modułu zaczynasz.

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 00.01 | [Czym jest FPGA i gdzie się go używa](00.01-czym-jest-fpga-i-gdzie-sie-go-uzywa.md) | — | — |
| 00.02 | [FPGA, mikrokontroler, procesor, GPU i ASIC — kiedy co](00.02-fpga-mikrokontroler-procesor-gpu-i-asic-kiedy-co.md) | — | — |
| 00.03 | [Instalacja: Quartus Prime Lite i Questa Starter](00.03-instalacja-quartus-prime-lite-i-questa-starter.md) | — | 🛠️ |
| 00.04 | [Instalacja: GHDL, Icarus Verilog, Verilator i OSS CAD Suite](00.04-instalacja-ghdl-icarus-verilog-verilator-i-oss.md) | — | — |
| 00.05 | [Edytor i podgląd przebiegów: VS Code, TerosHDL, GTKWave, Surfer](00.05-edytor-i-podglad-przebiegow-vs-code-teroshdl.md) | VHDL · Verilog · SystemVerilog | — |
| 00.06 | [Pierwszy projekt: migająca dioda w trzech językach](00.06-pierwszy-projekt-migajaca-dioda-w-trzech.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 00.07 | [Struktura repozytorium projektu FPGA i Git](00.07-struktura-repozytorium-projektu-fpga-i-git.md) | — | — |

## Po tym module potrafisz

- wyjaśnić, czym FPGA różni się od mikrokontrolera, procesora graficznego i układu ASIC i kiedy który wybrać,
- zainstalować Quartus Prime Lite, Questa Starter oraz otwarte symulatory GHDL, Icarus Verilog i Verilator,
- zsyntezować, zaimplementować i wgrać projekt na DECA oraz uruchomić symulację tego samego kodu,
- założyć repozytorium projektu FPGA z sensowną strukturą katalogów i plikiem .gitignore.

## Kod w module

- [hdl/](hdl/) — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [deca/](deca/) — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 00.01 Czym jest FPGA i gdzie się go używa
- [ ] 00.02 FPGA, mikrokontroler, procesor, GPU i ASIC — kiedy co
- [ ] 00.03 Instalacja: Quartus Prime Lite i Questa Starter
- [ ] 00.04 Instalacja: GHDL, Icarus Verilog, Verilator i OSS CAD Suite
- [ ] 00.05 Edytor i podgląd przebiegów: VS Code, TerosHDL, GTKWave, Surfer
- [ ] 00.06 Pierwszy projekt: migająca dioda w trzech językach
- [ ] 00.07 Struktura repozytorium projektu FPGA i Git
