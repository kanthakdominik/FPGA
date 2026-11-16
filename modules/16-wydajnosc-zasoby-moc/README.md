# 16 — Wydajność, zasoby i pobór mocy

> **Część IV** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 14 h · **Status:** 🔲 szkielet

## Po co ten moduł

Jak przyspieszyć projekt, zmieścić go w układzie i ograniczyć pobór mocy. Moduł kończy się metodyką zamykania timingu krok po kroku, opartą na praktyce dużych projektów.

## Wymagane wcześniej

[14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 16.01 | [Potokowanie i retiming](16.01-potokowanie-i-retiming.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 16.02 | [Współdzielenie zasobów i kompromis powierzchnia–szybkość](16.02-wspoldzielenie-zasobow-i-kompromis.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 16.03 | [Fanout, duplikacja rejestrów i głębokość logiki](16.03-fanout-duplikacja-rejestrow-i-glebokosc-logiki.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 16.04 | [Zamykanie timingu: metodyka krok po kroku](16.04-zamykanie-timingu-metodyka-krok-po-kroku.md) | — | 🛠️ | 🔲 |
| 16.05 | [Floorplanning i ograniczenia fizyczne](16.05-floorplanning-i-ograniczenia-fizyczne.md) | — | — | 🔲 |
| 16.06 | [Pobór mocy: statyczny i dynamiczny, szacowanie i redukcja](16.06-pobor-mocy-statyczny-i-dynamiczny-szacowanie-i.md) | — | 🛠️ | 🔲 |

## Po tym module potrafisz

- potokować ścieżki krytyczne i stosować retiming,
- wybierać kompromis między powierzchnią a szybkością,
- radzić sobie z dużym fanoutem i głęboką logiką,
- prowadzić zamykanie timingu i stosować ograniczenia fizyczne,
- oszacować pobór mocy i go zmniejszyć.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 16.01 Potokowanie i retiming
- [ ] 16.02 Współdzielenie zasobów i kompromis powierzchnia–szybkość
- [ ] 16.03 Fanout, duplikacja rejestrów i głębokość logiki
- [ ] 16.04 Zamykanie timingu: metodyka krok po kroku
- [ ] 16.05 Floorplanning i ograniczenia fizyczne
- [ ] 16.06 Pobór mocy: statyczny i dynamiczny, szacowanie i redukcja
