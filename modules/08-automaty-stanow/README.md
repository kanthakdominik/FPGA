# 08 — Automaty stanów i sterowanie

> **Część II** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 14 h · **Status:** ✅ pełny

## Po co ten moduł

Automaty stanów to sterowanie w niemal każdym projekcie FPGA. Moduł omawia style kodowania, kodowanie stanów, bezpieczne automaty oraz handshake valid/ready, a kończy się prostą ścieżką danych ze sterowaniem (FSMD).

## Wymagane wcześniej

[07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 08.01 | [Automat Moore'a i Mealy'ego w HDL — style kodowania](08.01-automat-moore-a-i-mealy-ego-w-hdl-style.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 08.02 | [Kodowanie stanów: binarne, one-hot, Graya](08.02-kodowanie-stanow-binarne-one-hot-graya.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 08.03 | [Bezpieczne automaty: stany nielegalne i odzyskiwanie](08.03-bezpieczne-automaty-stany-nielegalne-i.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 08.04 | [Eliminacja drgań styków i wykrywanie zboczy](08.04-eliminacja-drgan-stykow-i-wykrywanie-zboczy.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |
| 08.05 | [Handshake valid/ready i przepływ danych](08.05-handshake-valid-ready-i-przeplyw-danych.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 08.06 | [Ścieżka danych i sterowanie (FSMD) — prosty procesor sekwencyjny](08.06-sciezka-danych-i-sterowanie-fsmd-prosty.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |

## Po tym module potrafisz

- zakodować automat Moore'a i Mealy'ego w stylu jedno-, dwu- i trójprocesowym,
- dobrać kodowanie stanów i ocenić jego wpływ na zasoby i szybkość,
- zabezpieczyć automat przed stanami nielegalnymi,
- zaprojektować przepływ danych z sygnałami valid i ready,
- połączyć ścieżkę danych z automatem sterującym.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [deca/automaty](deca/automaty/) — projekt dla płytki Arrow DECA: procesor `tiny_cpu` liczący ciąg Fibonacciego (praca ciągła albo krokowa z przycisku) i porównanie liczby zboczy przycisku przed i po filtrze `debounce_fsm`; moduł nadrzędny w trzech językach, `automaty.sdc`, `utworz_projekt.tcl`, `Makefile` ([opis projektu](08.06-sciezka-danych-i-sterowanie-fsmd-prosty.md#na-płytce-deca), [opis płytki](../../plytka-deca/README.md)).
- Lint: kod Verilog i SystemVerilog modułu przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 08.01 Automat Moore'a i Mealy'ego w HDL — style kodowania
- [ ] 08.02 Kodowanie stanów: binarne, one-hot, Graya
- [ ] 08.03 Bezpieczne automaty: stany nielegalne i odzyskiwanie
- [ ] 08.04 Eliminacja drgań styków i wykrywanie zboczy
- [ ] 08.05 Handshake valid/ready i przepływ danych
- [ ] 08.06 Ścieżka danych i sterowanie (FSMD) — prosty procesor sekwencyjny
