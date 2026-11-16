# 19 — Arytmetyka i liczby w sprzęcie

> **Część V** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Liczby stałoprzecinkowe, mnożenie w blokach DSP, dzielenie, CORDIC i liczby zmiennoprzecinkowe. To podstawa każdego projektu DSP i jedno z ulubionych źródeł pytań rekrutacyjnych.

## Wymagane wcześniej

[07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 19.01 | [Stałoprzecinkowe formaty Q: skalowanie, zaokrąglanie, nasycenie](19.01-staloprzecinkowe-formaty-q-skalowanie.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 19.02 | [Mnożenie i bloki DSP — potokowanie](19.02-mnozenie-i-bloki-dsp-potokowanie.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 19.03 | [Dzielenie i pierwiastek: algorytmy iteracyjne](19.03-dzielenie-i-pierwiastek-algorytmy-iteracyjne.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 19.04 | [CORDIC](19.04-cordic.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 19.05 | [Liczby zmiennoprzecinkowe w FPGA: IEEE 754 i rdzenie IP](19.05-liczby-zmiennoprzecinkowe-w-fpga-ieee-754-i.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 19.06 | [Tablice i aproksymacja funkcji](19.06-tablice-i-aproksymacja-funkcji.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |

## Po tym module potrafisz

- zapisywać liczby w formacie Q, skalować je, zaokrąglać i nasycać,
- potokować mnożenie i dopasować je do bloków DSP,
- zaimplementować dzielenie i pierwiastek iteracyjnie,
- użyć algorytmu CORDIC do funkcji trygonometrycznych,
- ocenić, kiedy warto użyć liczb zmiennoprzecinkowych.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 19.01 Stałoprzecinkowe formaty Q: skalowanie, zaokrąglanie, nasycenie
- [ ] 19.02 Mnożenie i bloki DSP — potokowanie
- [ ] 19.03 Dzielenie i pierwiastek: algorytmy iteracyjne
- [ ] 19.04 CORDIC
- [ ] 19.05 Liczby zmiennoprzecinkowe w FPGA: IEEE 754 i rdzenie IP
- [ ] 19.06 Tablice i aproksymacja funkcji
