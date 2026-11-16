# Materiały o płytce DECA

[← płytka DECA](README.md)

Wszystko, co warto mieć pod ręką, pracując z DECA: dokumentacja producenta, schematy, gotowe projekty i biblioteki. Tematy w bazie odwołują się do tych materiałów z numerem strony lub ścieżką w repozytorium.

## Dokumentacja producenta

| Materiał | Co zawiera | Gdzie |
|----------|-----------|-------|
| **DECA User Manual** (Terasic, wersja z 20.07.2017, 134 s.) | Opis płytki, konfiguracja MAX 10, zegary, tabele pinów wszystkich peryferiów (rozdz. 3), System Builder (rozdz. 4), przykłady (rozdz. 5–7) | [kopia T. Verbeure'a](https://tomverbeure.github.io/assets/deca/deca_user_manual.pdf) · [kopia DECAfpga](https://github.com/DECAfpga/DECA_board/tree/main/Documents) · [strona płytki w Arrow](https://www.arrow.com/en/products/deca/arrow-development-tools) |
| **DECA Schematic** | Schemat płytki: banki I/O, zasilanie, zegary, USB-Blaster II, DDR3, QSPI, peryferia | [kopia T. Verbeure'a](https://tomverbeure.github.io/assets/deca/decaschematic.pdf) · [kopia DECAfpga](https://github.com/DECAfpga/DECA_board/tree/main/Documents) |
| **DECA Product Brief** | Dwustronicowa karta katalogowa | [kopia T. Verbeure'a](https://tomverbeure.github.io/assets/deca/arrowelectronicsdecadatasheetfinalpdf.pdf) |
| **DECA BOM** | Lista elementów — numery katalogowe układów na płytce (PHY, kodek, czujniki) | [kopia T. Verbeure'a](https://tomverbeure.github.io/assets/deca/decabom.xls) |
| **DECA System CD** | System Builder, projekty demonstracyjne Terasic (HDMI, Ethernet, DDR3, czujniki, karta SD) | odnośnik `cd-deca.terasic.com` z instrukcji; kopie projektów w repozytoriach poniżej |
| **Intel Community Wiki — DECA** | Opis płytki i lista projektów referencyjnych | [community.intel.com](https://community.intel.com/t5/FPGA-Wiki/DECA/ta-p/735458) |
| **MAX 10 — Nios II Simple Socket Server for DECA** | Oficjalny przykład Ethernet + TCP/IP | [altera.com](https://www.intel.com/content/www/us/en/design-example/714921/intel-max-10-fpga-nios-ii-processor-simple-socket-server-ethernet-design-example-for-arrow-s-deca-board.html) |

## Repozytoria i projekty

| Repozytorium | Co z niego bierzemy | Moduły |
|--------------|---------------------|--------|
| [tomverbeure/arrow_deca](https://github.com/tomverbeure/arrow_deca) i [recenzja płytki](https://tomverbeure.github.io/2021/04/23/Arrow-DECA-FPGA-board.html) | Minimalny działający projekt (dioda), napięcia banków I/O, ustawienia konfiguracji — punkt odniesienia dla `deca_piny.tcl` | 00, 03 |
| [DECAfpga/DECA_board](https://github.com/DECAfpga/DECA_board) | Dokumentacja, mapa złączy, szablony projektów Quartusa, LiteX, FuseSoC, poradnik przenoszenia projektów (HDMI, audio, karta SD); lista materiałów społeczności w `resources.md` | 00, 24, 25, 27 |
| [SoCFPGA-learning/DECA](https://github.com/SoCFPGA-learning/DECA) | Starsze repozytorium społeczności: przykładowe projekty (Pong, NES, ZX Spectrum z HDMI, test pamięci) | 24, 31 |
| [BrianHGinc/BrianHG-DDR3-Controller](https://github.com/BrianHGinc/BrianHG-DDR3-Controller) | Otwarty kontroler DDR3 dla MAX 10 z gotowymi projektami na DECA (400 MHz, obraz 1080p) | 23, 24 |
| [litex-hub/litex-boards](https://github.com/litex-hub/litex-boards) — `terasic_deca.py` | Niezależny opis pinów płytki (sprawdzenie krzyżowe) i system z procesorem RISC-V | 27 |
| [clash-lang/clash-starters](https://github.com/clash-lang/clash-starters) — katalog `deca` | Szablon projektu DECA dla języka Clash | 28 |

## Jak korzystać

- **Piny** bierz z [piny.md](piny.md) albo [deca_piny.tcl](deca_piny.tcl) — są przepisane z instrukcji i sprawdzone z LiteX oraz schematem.
- **Układ:** wiele płytek ma układ w wersji inżynierskiej `10M50DAF484C6GES` (tak ustawiają projekty T. Verbeure'a i DECAfpga). Instrukcja podaje wersję produkcyjną `10M50DAF484C6G`. Sprawdź napis na swoim układzie.
- **Projekty społeczności** powstały w różnych wersjach Quartusa (17.1–20.1). W nowszym Quartusie Lite otwierają się zwykle bez zmian; rdzenie IP (PLL, DDR3) mogą wymagać ponownego wygenerowania.
