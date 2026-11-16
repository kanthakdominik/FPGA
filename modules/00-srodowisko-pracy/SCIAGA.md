# Ściąga — 00 — Środowisko pracy i pierwszy projekt

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [00.01 — Czym jest FPGA i gdzie się go używa](00.01-czym-jest-fpga-i-gdzie-sie-go-uzywa.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| FPGA nie wykonuje programu — kod HDL opisuje sprzęt | zawsze; to podstawa myślenia przy pisaniu RTL |
| Wszystkie bloki opisane w HDL pracują równocześnie | zawsze |
| `.sof` → SRAM (ulotny), `.pof` → wewnętrzny flash MAX 10 (trwały) | MAX 10, Quartus |
| MAX 10 10M50: ok. 50 tys. LE, 1638 Kb RAM M9K, 4 PLL | płytka DECA |
| FPGA = bloki logiczne + połączenia + I/O + bloki wyspecjalizowane | ogólna budowa |

## [00.02 — FPGA, mikrokontroler, procesor, GPU i ASIC — kiedy co](00.02-fpga-mikrokontroler-procesor-gpu-i-asic-kiedy-co.md)

| Reguła | Kiedy obowiązuje |
|--------|------------------|
| FPGA wygrywa opóźnieniem, determinizmem i elastycznością interfejsów | wybór platformy |
| ASIC ma najniższy koszt jednostkowy i najwyższy koszt jednorazowy | produkcja masowa |
| GPU wygrywa przepustowością przy jednakowych operacjach na dużych zbiorach danych | obliczenia równoległe bez wymagań czasu rzeczywistego |
| Logika sterująca — procesor, ścieżka danych — FPGA | podział sprzęt–oprogramowanie |

## [00.03 — Instalacja: Quartus Prime Lite i Questa Starter](00.03-instalacja-quartus-prime-lite-i-questa-starter.md)

| Reguła | Kiedy obowiązuje |
|--------|------------------|
| MAX 10 → Quartus Prime **Lite** (darmowy) + plik obsługi MAX 10 `.qdz` | instalacja |
| Questa Starter: licencja darmowa z SSLC, ważna 12 miesięcy, przypisana do adresu MAC | symulacja w Questa |
| USB-Blaster II: `09fb:6010` przed i `09fb:6810` po załadowaniu firmware'u | reguły udev w Linuksie |
| `jtagconfig` — pierwszy test połączenia z płytką | zawsze przy problemach z programowaniem |
| Ścieżka instalacji bez spacji i polskich znaków | Windows i Linux |

## [00.04 — Instalacja: GHDL, Icarus Verilog, Verilator i OSS CAD Suite](00.04-instalacja-ghdl-icarus-verilog-verilator-i-oss.md)

| Reguła | Kiedy obowiązuje |
|--------|------------------|
| GHDL: zawsze `--std=08` | kod VHDL w tej bazie |
| Verilator ≥ 5 (`--binary --timing`) | testbenche SystemVerilog |
| `source ~/oss-cad-suite/environment` w każdej nowej konsoli | OSS CAD Suite na Linux/macOS |
| `python3 tools/run_hdl_tests.py <katalog>` — test całego modułu | po każdej zmianie w kodzie |

## [00.05 — Edytor i podgląd przebiegów: VS Code, TerosHDL, GTKWave, Surfer](00.05-edytor-i-podglad-przebiegow-vs-code-teroshdl.md)

| Reguła | Kiedy obowiązuje |
|--------|------------------|
| GHDL: `--wave=plik.ghw` (typy VHDL) albo `--vcd=plik.vcd` | zapis przebiegów VHDL |
| Icarus: `$dumpfile` + `$dumpvars(0, top)` | zapis przebiegów Verilog |
| Verilator: `--trace` (VCD) lub `--trace-fst` (FST) przy kompilacji | zapis przebiegów w Verilatorze |
| Zapis przebiegów włączany makrem lub opcją, nie na stałe | regresja jest wtedy szybsza |
| Zapisuj widok przeglądarki (`.gtkw`) | powtarzalne debugowanie |

## [00.06 — Pierwszy projekt: migająca dioda w trzech językach](00.06-pierwszy-projekt-migajaca-dioda-w-trzech.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| $\text{HALF} = f_\text{clk} / (2 f_\text{blink})$, szerokość $\lceil\log_2 \text{HALF}\rceil$ | dzielnik licznikowy |
| 50 MHz → 1 Hz: `HALF` = 25 000 000, licznik 25-bitowy | DECA, `MAX10_CLK1_50` |
| Diody DECA: 0 = świeci; przyciski: 0 = wciśnięty | moduł nadrzędny DECA |
| Każdy sygnał spoza domeny zegara przez synchronizator (2 FF) | przyciski, przełączniki, sygnały z innych zegarów |
| Zawsze `create_clock` w pliku SDC | każdy projekt |
| `.sof` — SRAM, chwilowo; `.pof` — wewnętrzny flash, trwale | programowanie MAX 10 |

## [00.07 — Struktura repozytorium projektu FPGA i Git](00.07-struktura-repozytorium-projektu-fpga-i-git.md)

| Reguła | Kiedy obowiązuje |
|--------|------------------|
| W repozytorium przepis (kod, ograniczenia, skrypty), nie wynik (bazy, raporty, bitstream) | każdy projekt |
| Projekt Quartusa tworzony skryptem Tcl, `.qsf` w `.gitignore` | ta baza, większe projekty |
| Bitstream działającej wersji — jako załącznik wydania z tagiem | wydania |
| Zielone testy przed scaleniem do gałęzi głównej | praca zespołowa |
