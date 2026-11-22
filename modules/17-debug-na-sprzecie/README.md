# 17 — Uruchamianie i debug na sprzęcie

> **Część IV** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 10 h

## Po co ten moduł

Co zrobić, gdy projekt działa w symulacji, a na płytce nie. Moduł uczy wbudowanych analizatorów logicznych (Signal Tap, ILA), sond JTAG i pomiarów przyrządami zewnętrznymi. Analizator budujemy też sami (`mini_ila`), żeby było jasne, co dzieje się w środku, a projekt DECA łączy bicie serca z trzech zegarów, miernik częstotliwości, mini_ila i In-System Sources and Probes obsługiwane skryptami Tcl. Pułapki „działa w symulacji, nie działa na płytce” są pokazane na żywo: ta sama symulacja na RTL i na netliście po syntezie daje różne wyniki.

## Wymagane wcześniej

[03 — Przepływ projektowy od RTL do bitstreamu](../03-przeplyw-projektowy/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 17.01 | [Strategia uruchamiania: od diody do analizatora logicznego](17.01-strategia-uruchamiania-od-diody-do-analizatora.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 17.02 | [Wbudowany analizator logiczny: Signal Tap i ILA](17.02-wbudowany-analizator-logiczny-signal-tap-i-ila.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 17.03 | [In-System Sources and Probes, VIO i JTAG-to-Avalon](17.03-in-system-sources-and-probes-vio-i-jtag-to.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 17.04 | [Pomiary zewnętrzne: oscyloskop, analizator logiczny, integralność sygnałów](17.04-pomiary-zewnetrzne-oscyloskop-analizator.md) | Python / inne | 🛠️ |
| 17.05 | [Działa w symulacji, nie działa na płytce — typowe przyczyny](17.05-dziala-w-symulacji-nie-dziala-na-plytce-typowe.md) | Python / inne | — |

## Po tym module potrafisz

- zaplanować uruchamianie projektu od najprostszych testów,
- użyć Signal Tap na DECA i opisać odpowiednik w Vivado (ILA),
- sterować i podglądać sygnały przez In-System Sources and Probes,
- zmierzyć sygnały oscyloskopem i analizatorem logicznym,
- rozpoznać typowe przyczyny rozbieżności symulacji ze sprzętem.

## Układy w module

- **`bicie_serca`** — dioda migająca z zadanym dzielnikiem, pierwszy test każdego projektu ([17.01](17.01-strategia-uruchamiania-od-diody-do-analizatora.md)).
- **`pomiar_czestotliwosci`** — miernik częstotliwości zegara w układzie: licznik Graya, synchronizator, okno pomiarowe ([17.01](17.01-strategia-uruchamiania-od-diody-do-analizatora.md)).
- **`mini_ila`** — wbudowany analizator logiczny w miniaturze: bufor kołowy, wyzwolenie wartością z maską (poziom lub zbocze), próbki przed wyzwoleniem ([17.02](17.02-wbudowany-analizator-logiczny-signal-tap-i-ila.md)).

## Kod w module

- `hdl/` — układy z samosprawdzającymi się testbenchami w trzech językach (`vhdl/`, `verilog/`, `sv/`). Uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [deca/debug/](deca/debug/) — projekt DECA: `deca_top` w trzech językach (PLL 100 MHz, bicie serca z trzech zegarów, miernik częstotliwości, mini_ila, dwie instancje In-System Sources and Probes, sygnały testowe na złączu P8), [debug.sdc](deca/debug/debug.sdc) (trzy zegary, zegar JTAG), skrypty `quartus_stp`: [czestotliwosci.tcl](deca/debug/czestotliwosci.tcl) (`make czestotliwosci`) i [ila_odczyt.tcl](deca/debug/ila_odczyt.tcl) (`make ila` → `raporty/ila.vcd`), wspólne [issp.tcl](deca/debug/issp.tcl), test skryptów na atrapach poleceń JTAG [test_skryptow.tcl](deca/debug/test_skryptow.tcl) oraz `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- [pulapki/](pulapki/) — pięć pułapek „działa w symulacji, nie działa na płytce” w wersji złej i poprawionej, [porownaj.py](pulapki/porownaj.py): synteza Yosysem i porównanie symulacji RTL z symulacją netlisty ([17.05](17.05-dziala-w-symulacji-nie-dziala-na-plytce-typowe.md)).
- [pomiary/obliczenia.py](pomiary/obliczenia.py) — liczby do pomiarów oscyloskopem i analizatorem: pasmo, czas narastania, masa sondy, długość krytyczna ([17.04](17.04-pomiary-zewnetrzne-oscyloskop-analizator.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
