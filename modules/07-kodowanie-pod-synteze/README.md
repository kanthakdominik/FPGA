# 07 — Kodowanie pod syntezę — wzorce RTL

> **Część II** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 20 h

## Po co ten moduł

Najważniejszy moduł praktyczny: jak pisać kod, z którego syntezator zbuduje dokładnie to, co masz w głowie. Każdy wzorzec jest pokazany w trzech językach, z wynikiem syntezy i implementacją na DECA.

## Wymagane wcześniej

[04 — VHDL](../04-vhdl/README.md), [05 — Verilog](../05-verilog/README.md), [06 — SystemVerilog do projektowania](../06-systemverilog-rtl/README.md), [02 — Architektura układów FPGA](../02-architektura-fpga/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 07.01 | [Myślenie sprzętowe: kod HDL to schemat, nie program](07.01-myslenie-sprzetowe-kod-hdl-to-schemat-nie.md) | VHDL · Verilog · SystemVerilog | — |
| 07.02 | [Rejestry i reset: synchroniczny, asynchroniczny, bez resetu](07.02-rejestry-i-reset-synchroniczny-asynchroniczny.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 07.03 | [Niezamierzone zatrzaski i pętle kombinacyjne](07.03-niezamierzone-zatrzaski-i-petle-kombinacyjne.md) | VHDL · Verilog · SystemVerilog | — |
| 07.04 | [Liczniki, dzielniki i clock enable](07.04-liczniki-dzielniki-i-clock-enable.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 07.05 | [Rejestry przesuwne, LFSR i linie opóźniające](07.05-rejestry-przesuwne-lfsr-i-linie-opozniajace.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 07.06 | [Wnioskowanie pamięci RAM i ROM](07.06-wnioskowanie-pamieci-ram-i-rom.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 07.07 | [Wnioskowanie mnożarek i bloków DSP](07.07-wnioskowanie-mnozarek-i-blokow-dsp.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 07.08 | [Parametryzacja i projekt wielokrotnego użytku](07.08-parametryzacja-i-projekt-wielokrotnego-uzytku.md) | VHDL · Verilog · SystemVerilog | — |
| 07.09 | [Styl kodu, lint i przeglądy: Verilator, Verible, VSG](07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md) | VHDL · Verilog · SystemVerilog | — |

## Po tym module potrafisz

- myśleć schematem: przewidzieć, jaki sprzęt powstanie z danego fragmentu kodu,
- wybrać strategię resetu i poprawnie opisać rejestry,
- unikać niezamierzonych zatrzasków i pętli kombinacyjnych,
- opisać liczniki, rejestry przesuwne i LFSR z clock enable zamiast dzielonych zegarów,
- wywnioskować pamięć RAM, ROM i bloki DSP bez instancjonowania prymitywów,
- pisać kod wielokrotnego użytku i sprawdzać go narzędziami lint.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [deca/wzorce](deca/wzorce/) — projekt dla płytki Arrow DECA łączący wzorce z modułu (synchronizator resetu, impulsy zezwolenia, licznik BCD, ROM, mnożenie, linie opóźniające): moduł nadrzędny w trzech językach, `wzorce.sdc`, `utworz_projekt.tcl` i `Makefile` ([opis projektu](07.04-liczniki-dzielniki-i-clock-enable.md#na-płytce-deca), [opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
