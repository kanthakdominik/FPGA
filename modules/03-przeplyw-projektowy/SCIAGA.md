# Ściąga — 03 — Przepływ projektowy od RTL do bitstreamu

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [03.01 — Etapy: opracowanie, synteza, mapowanie, rozmieszczanie, trasowanie, bitstream](03.01-etapy-opracowanie-synteza-mapowanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Etapy: opracowanie → synteza → mapowanie → rozmieszczanie → trasowanie → analiza czasowa → bitstream | każde narzędzie FPGA |
| Quartus: `quartus_map` → `quartus_fit` → `quartus_asm` → `quartus_sta` | Lite i Standard |
| Ograniczenia czasowe (SDC) wpływają na rozmieszczanie, nie tylko na raport | Quartus, Vivado |
| Wynik rozmieszczenia zależy od ziarna — małe zmiany kodu mogą zmienić timing | zamykanie timingu |
| Opóźnienia połączeń są znane dopiero po trasowaniu | czytanie raportów syntezy |

## [03.02 — Synteza: co robi syntezator i jak czytać jego raport](03.02-synteza-co-robi-syntezator-i-jak-czytac-jego.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Logika bez wpływu na wyjścia jest usuwana | zawsze — sygnały debugowe wyprowadź albo zachowaj atrybutem |
| Identyczne rejestry są łączone; celowe kopie chroni `preserve` | powielanie rejestrów |
| *Registers Removed During Synthesis* — czytaj po każdej większej zmianie | Quartus |
| Struktura opisu wpływa na sprzęt: „mux przed operatorem” daje jeden operator | oszczędzanie zasobów |
| Raport syntezy podaje szacunki; liczy się raport po implementacji | timing |

## [03.03 — Ograniczenia: piny, standardy I/O i zegary (QSF, SDC, XDC, PCF)](03.03-ograniczenia-piny-standardy-i-o-i-zegary-qsf.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Piny i standardy: QSF (Quartus), XDC (Vivado), PCF/LPF/CST (otwarte narzędzia, Gowin) | wszystkie projekty |
| Ograniczenia czasowe: SDC — wspólna składnia Quartusa i Vivado | wszystkie projekty |
| Każdy zegar wejściowy — `create_clock`; zegary PLL — `derive_pll_clocks` lub `create_generated_clock` | Quartus |
| Każdy pin — `set_input_delay`/`set_output_delay` albo uzasadnione `set_false_path` | brak ścieżek nieograniczonych |
| `set_false_path` i `set_clock_groups` wyłączają sprawdzanie — tylko z uzasadnieniem | zawsze |
| W tej bazie QSF generuje skrypt z `deca_piny.tcl` | projekty DECA |

## [03.04 — Raporty: zasoby, czasy i ostrzeżenia, których nie wolno ignorować](03.04-raporty-zasoby-czasy-i-ostrzezenia-ktorych-nie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Zero błędów, zero niewyjaśnionych ostrzeżeń, dodatni zapas w każdym modelu | każdy projekt oddawany dalej |
| Zatrzask, obcięcie, wielokrotne sterowanie, pętla kombinacyjna, zegar z logiki — zawsze do wyjaśnienia | ostrzeżenia syntezy |
| *Unconstrained Paths* musi być pusty | analiza czasowa |
| Zużycie zasobów z raportu fittera, nie syntezy | ocena wielkości projektu |
| Wyciszone ostrzeżenia — z komentarzem w repozytorium | praca zespołowa |

## [03.05 — Praca skryptowa: Tcl, tryb wsadowy i Makefile](03.05-praca-skryptowa-tcl-tryb-wsadowy-i-makefile.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| GUI to nakładka na polecenia Tcl i programy wsadowe | Quartus, Vivado |
| `quartus_sh -t skrypt.tcl` — skrypt; `--flow compile` — pełna kompilacja | Quartus |
| Tcl: `$` — zmienna, `[ ]` — polecenie, `{ }` — bez podstawień | każdy skrypt |
| Nazwy z nawiasami kwadratowymi w Tcl — w `{ }` | `LED[0]`, `KEY[*]` |
| Projekt odtwarzalny = skrypty + źródła w repozytorium, bez plików generowanych | praca zespołowa |

## [03.06 — Otwarty przepływ: Yosys, nextpnr i narzędzia konfiguracyjne](03.06-otwarty-przeplyw-yosys-nextpnr-i-narzedzia.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Yosys (synteza) → nextpnr (implementacja) → icepack/ecppack/gowin_pack (bitstream) → openFPGALoader | iCE40, ECP5, Gowin |
| VHDL do Yosysa przez GHDL (*ghdl-yosys-plugin*) | otwarty przepływ dla VHDL |
| MAX 10: brak otwartego bitstreamu; Yosys do sprawdzania kodu, openFPGALoader do programowania | płytka DECA |
| Liczby zasobów z Yosysa są orientacyjne — porównuj wersje kodu, nie narzędzia | ocena zasobów |

## [03.07 — Programowanie układu: JTAG, pliki .sof i .pof, pamięć konfiguracyjna](03.07-programowanie-ukladu-jtag-pliki-sof-i-pof.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| JTAG: TCK, TMS, TDI, TDO; układy w łańcuchu, TDO → TDI następnego | wszystkie FPGA |
| `.sof` → SRAM (ulotne), `.pof` → flash (trwałe), `.jic` → zewnętrzna flash, `.svf` → dowolne narzędzie JTAG | Quartus |
| `quartus_pgm -c <kabel> -m jtag -o "p;plik"` | programowanie z linii poleceń |
| USB-Blaster II: `09fb:6010` przed i `09fb:6810` po załadowaniu oprogramowania | reguły udev na Linuksie |
| `jtagconfig` — pierwszy krok diagnostyki | zawsze, gdy programowanie nie działa |
