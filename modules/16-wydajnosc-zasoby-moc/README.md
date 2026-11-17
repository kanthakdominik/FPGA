# 16 — Wydajność, zasoby i pobór mocy

> **Część IV** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 14 h · **Status:** ✅ pełny

## Po co ten moduł

Jak przyspieszyć projekt, zmieścić go w układzie i ograniczyć pobór mocy. Moduł zawiera metodykę zamykania timingu krok po kroku, opartą na praktyce dużych projektów. Każda technika jest zmierzona: te same układy w kilku wariantach przechodzą przez Yosys i nextpnr-ecp5 (f_max, zasoby, fanout, wpływ ziarna i rozmieszczenia), a moc dynamiczna jest szacowana z aktywności netlisty w symulacji — wszystko w CI. Projekt DECA (150 MHz) służy do zamykania timingu i analizy mocy w Quartusie.

## Wymagane wcześniej

[14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 16.01 | [Potokowanie i retiming](16.01-potokowanie-i-retiming.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |
| 16.02 | [Współdzielenie zasobów i kompromis powierzchnia–szybkość](16.02-wspoldzielenie-zasobow-i-kompromis.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 16.03 | [Fanout, duplikacja rejestrów i głębokość logiki](16.03-fanout-duplikacja-rejestrow-i-glebokosc-logiki.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 16.04 | [Zamykanie timingu: metodyka krok po kroku](16.04-zamykanie-timingu-metodyka-krok-po-kroku.md) | Python / inne | 🛠️ | ✅ |
| 16.05 | [Floorplanning i ograniczenia fizyczne](16.05-floorplanning-i-ograniczenia-fizyczne.md) | Python / inne | — | ✅ |
| 16.06 | [Pobór mocy: statyczny i dynamiczny, szacowanie i redukcja](16.06-pobor-mocy-statyczny-i-dynamiczny-szacowanie-i.md) | VHDL · Verilog · SystemVerilog | 🛠️ | ✅ |

## Po tym module potrafisz

- potokować ścieżki krytyczne i stosować retiming,
- wybierać kompromis między powierzchnią a szybkością,
- radzić sobie z dużym fanoutem i głęboką logiką,
- prowadzić zamykanie timingu i stosować ograniczenia fizyczne,
- oszacować pobór mocy i go zmniejszyć.

## Układy w module

- **`sumator_drzewo`** — suma ośmiu liczb drzewem z parametrem stopni potoku `PIPE` i rejestrów do retimingu `RET` ([16.01](16.01-potokowanie-i-retiming.md)).
- **`iloczyn_rown` / `iloczyn_szer`** — iloczyn skalarny na czterech mnożarkach albo na jednej w czterech taktach; **`mnoz_wybor`** — `sel ? a*b : c*d` z dwiema mnożarkami albo jedną współdzieloną ([16.02](16.02-wspoldzielenie-zasobow-i-kompromis.md)).
- **`max_n`** — maksimum z 16 liczb łańcuchem albo drzewem; **`rozgalezienie`** — rejestr przesuwny z zezwoleniem o dużym fanoucie i duplikacją rejestru sterującego ([16.03](16.03-fanout-duplikacja-rejestrow-i-glebokosc-logiki.md)).
- **`izolacja_operandow`** — mnożarka z argumentami ładowanymi w każdym takcie albo tylko przy ważnych danych ([16.06](16.06-pobor-mocy-statyczny-i-dynamiczny-szacowanie-i.md)).

## Kod w module

- `hdl/` — wszystkie układy z samosprawdzającymi się testbenchami w trzech językach (`vhdl/`, `verilog/`, `sv/`); testbenche porównują warianty tego samego układu na wspólnych danych (latencja, przepustowość, liczba przełączeń). Uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [wydajnosc/](wydajnosc/) — [eksperymenty.py](wydajnosc/eksperymenty.py) (Yosys `synth_ecp5` + nextpnr-ecp5: potok, retiming, współdzielenie, głębokość logiki, fanout, ziarna, obszary rozmieszczenia — `e1`–`e5`), [region.py](wydajnosc/region.py) i [floorplan_demo.v](wydajnosc/floorplan_demo.v) (obszary w nextpnr), [moc.py](wydajnosc/moc.py) z [tb_moc.v](wydajnosc/tb_moc.v) (aktywność netlisty bramkowej z VCD i szacowanie mocy dynamicznej).
- [deca/wydajnosc/](deca/wydajnosc/) — projekt DECA: `deca_top` w trzech językach (PLL 150 MHz, drzewo sumatorów z `PIPE`, mnożarka z `ISO`, sumy kontrolne na diodach), [wydajnosc.sdc](deca/wydajnosc/wydajnosc.sdc), [ziarna.tcl](deca/wydajnosc/ziarna.tcl) (`make ziarna` — przegląd ziaren Fittera), `make moc` (Power Analyzer i plik do Early Power Estimatora) oraz `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- CI: zadanie *Analiza czasowa, CDC i wydajność* w [checks.yml](../../.github/workflows/checks.yml) — `moc.py` i `eksperymenty.py` z tabelą wyników w podsumowaniu przebiegu, raporty nextpnr jako artefakt.
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

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
