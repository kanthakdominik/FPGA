# 19 — Arytmetyka i liczby w sprzęcie

> **Część V** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 16 h

## Po co ten moduł

Liczby stałoprzecinkowe z poprawnym zaokrąglaniem i nasyceniem, mnożenie w blokach DSP (także szersze niż blok i zespolone), dzielenie i pierwiastek, CORDIC, mnożenie zmiennoprzecinkowe IEEE 754 i aproksymacja funkcji z tablic. To podstawa każdego projektu DSP i jedno z ulubionych źródeł pytań rekrutacyjnych. Każdy układ jest sprawdzany wyczerpująco albo na tysiącach wektorów, a eksperymenty w Yosysie i nextpnr pokazują ich koszt i f_max.

## Wymagane wcześniej

[07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 19.01 | [Stałoprzecinkowe formaty Q: skalowanie, zaokrąglanie, nasycenie](19.01-staloprzecinkowe-formaty-q-skalowanie.md) | VHDL · Verilog · SystemVerilog | — |
| 19.02 | [Mnożenie i bloki DSP — potokowanie](19.02-mnozenie-i-bloki-dsp-potokowanie.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 19.03 | [Dzielenie i pierwiastek: algorytmy iteracyjne](19.03-dzielenie-i-pierwiastek-algorytmy-iteracyjne.md) | VHDL · Verilog · SystemVerilog | — |
| 19.04 | [CORDIC](19.04-cordic.md) | VHDL · Verilog · SystemVerilog | — |
| 19.05 | [Liczby zmiennoprzecinkowe w FPGA: IEEE 754 i rdzenie IP](19.05-liczby-zmiennoprzecinkowe-w-fpga-ieee-754-i.md) | VHDL · Verilog · SystemVerilog | — |
| 19.06 | [Tablice i aproksymacja funkcji](19.06-tablice-i-aproksymacja-funkcji.md) | VHDL · Verilog · SystemVerilog | — |

## Po tym module potrafisz

- zapisywać liczby w formacie Q, skalować je, zaokrąglać i nasycać,
- potokować mnożenie i dopasować je do bloków DSP,
- zaimplementować dzielenie i pierwiastek iteracyjnie,
- użyć algorytmu CORDIC do funkcji trygonometrycznych,
- ocenić, kiedy warto użyć liczb zmiennoprzecinkowych, i zbudować mnożarkę IEEE 754,
- aproksymować funkcje tablicami z interpolacją i dobrać ich rozmiar do wymaganego błędu.

## Układy w module

- **`q_zmien`, `q_mnoz`** — zmiana formatu Q z trzema sposobami zaokrąglania i nasyceniem, mnożenie Q ([19.01](19.01-staloprzecinkowe-formaty-q-skalowanie.md)).
- **`mnoz_potok`, `mnoz_szeroki`, `mnoz_zesp`** — mnożarka z parametrem opóźnienia (ze znakiem i bez), 34 × 34 z czterech bloków 18 × 18, mnożenie zespolone czterema i trzema mnożeniami ([19.02](19.02-mnozenie-i-bloki-dsp-potokowanie.md)).
- **`dziel_iter`, `dziel_potok`, `pierw_iter`** — dzielenie bit na takt (ze znakiem, konwencja RISC-V dla przypadków specjalnych), dzielenie w pełnym potoku, pierwiastek całkowity ([19.03](19.03-dzielenie-i-pierwiastek-algorytmy-iteracyjne.md)).
- **`cordic`** — CORDIC w potoku, tryby obrotu i wektorowania, pełny okrąg ([19.04](19.04-cordic.md)).
- **`fp32_mnoz`** — mnożenie IEEE 754 binary32 z zaokrągleniem do najbliższej parzystej, NaN, ∞, DAZ/FTZ ([19.05](19.05-liczby-zmiennoprzecinkowe-w-fpga-ieee-754-i.md)).
- **`interp_lin`** — aproksymacja funkcji interpolacją liniową z tablic minimax ([19.06](19.06-tablice-i-aproksymacja-funkcji.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)); `hdl/dane/` — generatory i dane testów: [gen_fp32.py](hdl/dane/gen_fp32.py) (wektory binary32 z modelem sprawdzonym względem IEEE 754), [gen_aproks.py](hdl/dane/gen_aproks.py) (tablice interpolacji i porównanie metod).
- [arytmetyka/](arytmetyka/) — [eksperymenty.py](arytmetyka/eksperymenty.py): synteza Yosysem i rozmieszczenie nextpnr-ecp5 mnożarek, dzielników, CORDIC, mnożarki FP i interpolatora (f_max, LUT, przerzutniki, bloki 18 × 18); [cordic_model.py](arytmetyka/cordic_model.py): model CORDIC bit w bit i tabela błędów dla różnych N, A, G.
- [deca/mnozenie/](deca/mnozenie/) — test mnożarek na płytce: dwie realizacje mnożenia 34 × 34 i zespolonego porównywane w każdym takcie na danych z LFSR; `make raporty` zapisuje użycie bloków mnożarek i f_max.
- Projekt DECA: `deca_top` w trzech językach, `.sdc` i `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- CI: testbenche, lint, synteza i kompilacja modułów DECA w zadaniach ogólnych; eksperymenty w zadaniu *Analiza czasowa, CDC, wydajność i debug* w [checks.yml](../../.github/workflows/checks.yml).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

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
