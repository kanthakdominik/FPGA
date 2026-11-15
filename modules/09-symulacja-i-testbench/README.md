# 09 — Symulacja i testbenche

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** RTL, weryfikacja · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Jak działa symulator i jak pisać testbenche, które same sprawdzają wynik. Każdy przykład jest w trzech językach i uruchamia się w otwartych symulatorach oraz w Questa — na swoim komputerze i automatycznie w GitHub Actions.

## Wymagane wcześniej

[04 — VHDL](../04-vhdl/README.md), [05 — Verilog](../05-verilog/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 09.01 | [Jak działa symulator: zdarzenia, delta cykle, regiony planowania](09.01-jak-dziala-symulator-zdarzenia-delta-cykle.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 09.02 | [Pierwszy testbench: zegar, reset i pobudzenia](09.02-pierwszy-testbench-zegar-reset-i-pobudzenia.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 09.03 | [Testbench samosprawdzający: model referencyjny i porównanie](09.03-testbench-samosprawdzajacy-model-referencyjny-i.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 09.04 | [Przebiegi: VCD, FST, GTKWave, Surfer i Questa](09.04-przebiegi-vcd-fst-gtkwave-surfer-i-questa.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 09.05 | [Wektory testowe z plików](09.05-wektory-testowe-z-plikow.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 09.06 | [Symulacja po syntezie i z opóźnieniami](09.06-symulacja-po-syntezie-i-z-opoznieniami.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 09.07 | [Regresja i automatyzacja: skrypty, Makefile, CI](09.07-regresja-i-automatyzacja-skrypty-makefile-ci.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |

## Po tym module potrafisz

- wyjaśnić kolejkę zdarzeń, delta cykle i regiony planowania,
- napisać testbench z zegarem, resetem i pobudzeniami,
- zbudować testbench samosprawdzający z modelem referencyjnym,
- analizować przebiegi i wczytywać wektory testowe z plików,
- zautomatyzować regresję skryptem i w CI.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 09.01 Jak działa symulator: zdarzenia, delta cykle, regiony planowania
- [ ] 09.02 Pierwszy testbench: zegar, reset i pobudzenia
- [ ] 09.03 Testbench samosprawdzający: model referencyjny i porównanie
- [ ] 09.04 Przebiegi: VCD, FST, GTKWave, Surfer i Questa
- [ ] 09.05 Wektory testowe z plików
- [ ] 09.06 Symulacja po syntezie i z opóźnieniami
- [ ] 09.07 Regresja i automatyzacja: skrypty, Makefile, CI
