# 01 — Logika cyfrowa dla projektanta FPGA

> **Część I** · **Oznaczenia:** 🟢🛠️💼 · **Ścieżki:** RTL, weryfikacja, DECA · **Szacowany czas:** ok. 14 h

## Po co ten moduł

Powtórka techniki cyfrowej pod kątem tego, czego używa się w FPGA na co dzień: reprezentacja liczb, bloki kombinacyjne, przerzutniki, parametry czasowe i automaty. To fundament pod wszystkie kolejne moduły i ulubiony materiał na pierwsze pytania rozmowy kwalifikacyjnej.

## Wymagane wcześniej

[00 — Środowisko pracy i pierwszy projekt](../00-srodowisko-pracy/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 01.01 | [Systemy liczbowe, kody i liczby ze znakiem](01.01-systemy-liczbowe-kody-i-liczby-ze-znakiem.md) | — | — |
| 01.02 | [Algebra Boole'a i minimalizacja — co z tego robi syntezator](01.02-algebra-boole-a-i-minimalizacja-co-z-tego-robi.md) | — | — |
| 01.03 | [Bloki kombinacyjne: multipleksery, dekodery, enkodery, komparatory](01.03-bloki-kombinacyjne-multipleksery-dekodery.md) | VHDL · Verilog · SystemVerilog | 🛠️ `logika` |
| 01.04 | [Układy arytmetyczne: sumatory, przeniesienia, mnożenie](01.04-uklady-arytmetyczne-sumatory-przeniesienia.md) | VHDL · Verilog · SystemVerilog | 🛠️ `logika` |
| 01.05 | [Przerzutniki, zatrzaski i rejestry](01.05-przerzutniki-zatrzaski-i-rejestry.md) | VHDL · Verilog · SystemVerilog | — |
| 01.06 | [Parametry czasowe: propagacja, setup, hold, clock-to-out](01.06-parametry-czasowe-propagacja-setup-hold-clock.md) | — | — |
| 01.07 | [Metastabilność — pierwsze spotkanie](01.07-metastabilnosc-pierwsze-spotkanie.md) | — | — |
| 01.08 | [Automaty skończone na papierze: Moore i Mealy](01.08-automaty-skonczone-na-papierze-moore-i-mealy.md) | — | — |

## Po tym module potrafisz

- przeliczać liczby między systemami i zapisywać liczby ze znakiem w kodzie U2,
- zaprojektować na papierze multiplekser, dekoder, enkoder priorytetowy i sumator,
- odróżnić zatrzask od przerzutnika i wyjaśnić czasy setup, hold i clock-to-out,
- narysować automat Moore'a i Mealy'ego dla prostego zadania.

## Kod w module

- [hdl/](hdl/) — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [deca/](deca/) — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 01.01 Systemy liczbowe, kody i liczby ze znakiem
- [ ] 01.02 Algebra Boole'a i minimalizacja — co z tego robi syntezator
- [ ] 01.03 Bloki kombinacyjne: multipleksery, dekodery, enkodery, komparatory
- [ ] 01.04 Układy arytmetyczne: sumatory, przeniesienia, mnożenie
- [ ] 01.05 Przerzutniki, zatrzaski i rejestry
- [ ] 01.06 Parametry czasowe: propagacja, setup, hold, clock-to-out
- [ ] 01.07 Metastabilność — pierwsze spotkanie
- [ ] 01.08 Automaty skończone na papierze: Moore i Mealy
