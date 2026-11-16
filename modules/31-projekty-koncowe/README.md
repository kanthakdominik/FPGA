# 31 — Projekty końcowe na DECA

> **Część VII** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** DECA · **Szacowany czas:** ok. 60 h · **Status:** 🔲 szkielet

## Po co ten moduł

Sześć większych projektów, które łączą wiedzę z całej bazy i nadają się do portfolio. Każdy ma specyfikację, architekturę, plan weryfikacji, implementację na DECA i listę rozszerzeń.

## Wymagane wcześniej

[20 — Interfejsy szeregowe niskiej szybkości](../20-interfejsy-szeregowe/README.md), [24 — Wideo i grafika](../24-wideo-i-grafika/README.md), [27 — Procesory w FPGA i systemy SoC](../27-procesory-i-soc/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 31.01 | [Projekt 1: zegar i stoper sterowany komendami przez UART](31.01-projekt-1-zegar-i-stoper-sterowany-komendami.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 31.02 | [Projekt 2: oscyloskop na wbudowanym ADC z obrazem przez HDMI](31.02-projekt-2-oscyloskop-na-wbudowanym-adc-z.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 31.03 | [Projekt 3: syntezator dźwięku sterowany przez UART lub MIDI](31.03-projekt-3-syntezator-dzwieku-sterowany-przez.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 31.04 | [Projekt 4: system z Nios V, DDR3 i strumieniem UDP](31.04-projekt-4-system-z-nios-v-ddr3-i-strumieniem-udp.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 31.05 | [Projekt 5: przetwarzanie obrazu z kamery MIPI w czasie rzeczywistym](31.05-projekt-5-przetwarzanie-obrazu-z-kamery-mipi-w.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 31.06 | [Projekt 6: własny procesor RISC-V z peryferiami](31.06-projekt-6-wlasny-procesor-risc-v-z-peryferiami.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |

## Po tym module potrafisz

- przejść pełny cykl projektu: specyfikacja, architektura, RTL, weryfikacja, implementacja, uruchomienie,
- pokazać na rozmowie kwalifikacyjnej działające projekty z dokumentacją.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 31.01 Projekt 1: zegar i stoper sterowany komendami przez UART
- [ ] 31.02 Projekt 2: oscyloskop na wbudowanym ADC z obrazem przez HDMI
- [ ] 31.03 Projekt 3: syntezator dźwięku sterowany przez UART lub MIDI
- [ ] 31.04 Projekt 4: system z Nios V, DDR3 i strumieniem UDP
- [ ] 31.05 Projekt 5: przetwarzanie obrazu z kamery MIPI w czasie rzeczywistym
- [ ] 31.06 Projekt 6: własny procesor RISC-V z peryferiami
