# 14 — Statyczna analiza czasowa (STA)

> **Część IV** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 16 h · **Status:** ✅ pełny

## Po co ten moduł

Jak narzędzie sprawdza, czy projekt zadziała z zadaną częstotliwością, i jak mu to poprawnie opisać. Ograniczenia SDC są wspólne dla Quartusa, Vivado (XDC) i wielu innych narzędzi. Każde zjawisko z tekstów — setup, hold, skew, niepewność, narożniki, opóźnienia wejść i wyjść, ścieżki wielotaktowe, interfejs z zegarem przesyłanym — jest policzone przez otwarty silnik STA (OpenSTA) na netliście z Yosysa i sprawdzane w CI, a ten sam układ ma projekt DECA z kompletem ograniczeń dla Quartusa.

## Wymagane wcześniej

[03 — Przepływ projektowy od RTL do bitstreamu](../03-przeplyw-projektowy/README.md), [07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 14.01 | [Ścieżki czasowe, setup, hold i zapas (slack)](14.01-sciezki-czasowe-setup-hold-i-zapas-slack.md) | Python / inne | — | ✅ |
| 14.02 | [Zegar w praktyce: skew, jitter i niepewność](14.02-zegar-w-praktyce-skew-jitter-i-niepewnosc.md) | Python / inne | — | ✅ |
| 14.03 | [Ograniczenia SDC: zegary, zegary generowane, opóźnienia wejść i wyjść](14.03-ograniczenia-sdc-zegary-zegary-generowane.md) | Python / inne | 🛠️ | ✅ |
| 14.04 | [Wyjątki: false path, multicycle, max/min delay](14.04-wyjatki-false-path-multicycle-max-min-delay.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |
| 14.05 | [Czytanie raportów: Timing Analyzer i Vivado](14.05-czytanie-raportow-timing-analyzer-i-vivado.md) | Python / inne | 🛠️ | ✅ |
| 14.06 | [Ograniczenia interfejsów źródłowo-synchronicznych](14.06-ograniczenia-interfejsow-zrodlowo.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |

## Po tym module potrafisz

- policzyć zapas setup i hold dla ścieżki rejestr–rejestr,
- uwzględnić skew, jitter i niepewność zegara,
- napisać ograniczenia SDC dla zegarów, wejść i wyjść,
- poprawnie stosować false path, multicycle i max/min delay,
- czytać raporty Timing Analyzera i Vivado.

## Układ analizowany w module

- **`dzielnik_mc`** — dzielnik 16/8 kombinacyjny z rejestrami argumentów i wyniku: argumenty zapisywane przy `start`, wynik dokładnie N taktów później — ścieżka wielotaktowa ([14.04](14.04-wyjatki-false-path-multicycle-max-min-delay.md)), a zarazem najdłuższa ścieżka projektu ([14.01](14.01-sciezki-czasowe-setup-hold-i-zapas-slack.md)).
- **`spi_master`** — SPI w trybie 0, 8 bitów, zegar SCLK z rejestru (clk / 2·DIV): wyjścia MOSI/CS_N i wejście MISO opisane względem zegara przesyłanego ([14.06](14.06-ograniczenia-interfejsow-zrodlowo.md)).
- **`sta_demo`** — oba układy razem, syntetyzowane do biblioteki NanGate 45 nm dla OpenSTA i do ECP5 dla nextpnr; na DECA — z PLL 100 MHz (`deca_top`).

## Kod w module

- `hdl/` — `dzielnik_mc` i `spi_master` z samosprawdzającymi się testbenchami w trzech językach (`vhdl/`, `verilog/`, `sv/`); testbenche sprawdzają też warunki, na których opierają się ograniczenia (stabilność argumentów, chwila zapisu wyniku, czasy MOSI względem SCLK). Uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [sta/](sta/) — eksperymenty analizy czasowej: synteza do komórek Liberty ([synteza_asic.tcl](sta/synteza_asic.tcl)), skrypty OpenSTA `e01`–`e06` (po jednym na temat), [sprawdz_sta.py](sta/sprawdz_sta.py) porównujący wyniki z oczekiwanymi i zależnościami liczbowymi oraz uruchamiający nextpnr-ecp5 (f_max w trzech klasach szybkości, skład ścieżki krytycznej), [obliczenia.py](sta/obliczenia.py) — każda liczba z przykładów w tekstach.
- [deca/sta/](deca/sta/) — projekt DECA: `deca_top` w trzech językach (PLL 50 → 100 MHz, dzielnik z N = 8, SPI 25 MHz na złączu P8), ograniczenia [sta.sdc](deca/sta/sta.sdc) (zegary, zegary generowane, wyjątki, interfejs SPI), [raporty.tcl](deca/sta/raporty.tcl) (`make raporty`) i `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- CI: zadanie *Analiza czasowa, CDC i wydajność* w [checks.yml](../../.github/workflows/checks.yml) — OpenSTA budowany ze źródeł (pamięć podręczna), OSS CAD Suite, tabela wyników w podsumowaniu przebiegu, raporty jako artefakt.
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 14.01 Ścieżki czasowe, setup, hold i zapas (slack)
- [ ] 14.02 Zegar w praktyce: skew, jitter i niepewność
- [ ] 14.03 Ograniczenia SDC: zegary, zegary generowane, opóźnienia wejść i wyjść
- [ ] 14.04 Wyjątki: false path, multicycle, max/min delay
- [ ] 14.05 Czytanie raportów: Timing Analyzer i Vivado
- [ ] 14.06 Ograniczenia interfejsów źródłowo-synchronicznych
