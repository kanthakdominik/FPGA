# 04 — VHDL

> **Część II** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL, weryfikacja · **Szacowany czas:** ok. 24 h

## Po co ten moduł

Język VHDL od podstaw do konstrukcji używanych w przemyśle — z naciskiem na silne typowanie, pakiet numeric_std i różnicę między sygnałem a zmienną. VHDL dominuje w europejskim przemyśle, lotnictwie i obronności.

## Wymagane wcześniej

[01 — Logika cyfrowa dla projektanta FPGA](../01-logika-cyfrowa/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 04.01 | [Struktura projektu: biblioteki, entity i architecture](04.01-struktura-projektu-biblioteki-entity-i.md) | VHDL · Verilog · SystemVerilog | — |
| 04.02 | [Typy: std_logic, wektory, numeric_std, integer, typy wyliczeniowe i rekordy](04.02-typy-std-logic-wektory-numeric-std-integer-typy.md) | VHDL · Verilog · SystemVerilog | — |
| 04.03 | [Instrukcje współbieżne: przypisania, when-else, with-select](04.03-instrukcje-wspolbiezne-przypisania-when-else.md) | VHDL · Verilog · SystemVerilog | — |
| 04.04 | [Procesy, lista wrażliwości, sygnały a zmienne](04.04-procesy-lista-wrazliwosci-sygnaly-a-zmienne.md) | VHDL · Verilog · SystemVerilog | — |
| 04.05 | [Instrukcje sekwencyjne: if, case i pętle](04.05-instrukcje-sekwencyjne-if-case-i-petle.md) | VHDL · Verilog · SystemVerilog | — |
| 04.06 | [Hierarchia: komponenty, instancjonowanie, generic i generate](04.06-hierarchia-komponenty-instancjonowanie-generic.md) | VHDL · Verilog · SystemVerilog | — |
| 04.07 | [Pakiety, funkcje, procedury i atrybuty](04.07-pakiety-funkcje-procedury-i-atrybuty.md) | VHDL · Verilog · SystemVerilog | — |
| 04.08 | [VHDL-2008 i VHDL-2019 — co ułatwiają](04.08-vhdl-2008-i-vhdl-2019-co-ulatwiaja.md) | VHDL · Verilog · SystemVerilog | — |
| 04.09 | [Pułapki VHDL: rozdzielczość sygnałów, konwersje i delta cykle](04.09-pulapki-vhdl-rozdzielczosc-sygnalow-konwersje-i.md) | VHDL · Verilog · SystemVerilog | — |

## Po tym module potrafisz

- napisać i zinstancjonować parametryzowany moduł w VHDL,
- poprawnie używać typów std_logic, unsigned i signed oraz konwersji z numeric_std,
- opisać logikę kombinacyjną i sekwencyjną procesami i instrukcjami współbieżnymi,
- używać pakietów, funkcji, rekordów i instrukcji generate,
- rozpoznać typowe pułapki: niepełna lista wrażliwości, konwersje, delta cykle.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
