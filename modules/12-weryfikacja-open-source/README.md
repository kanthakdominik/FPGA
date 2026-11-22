# 12 — Weryfikacja z otwartymi narzędziami

> **Część III** · **Oznaczenia:** 🔍 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 16 h

## Po co ten moduł

Weryfikacja bez drogich licencji: cocotb (testy w Pythonie), VUnit, OSVVM i UVVM dla VHDL oraz Verilator. Te narzędzia działają w GitHub Actions i coraz częściej także w firmach.

## Wymagane wcześniej

[09 — Symulacja i testbenche](../09-symulacja-i-testbench/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 12.01 | [cocotb: testbench w Pythonie](12.01-cocotb-testbench-w-pythonie.md) | Python / inne | — |
| 12.02 | [VUnit: testy jednostkowe dla VHDL i SystemVeriloga](12.02-vunit-testy-jednostkowe-dla-vhdl-i.md) | VHDL · Verilog · SystemVerilog | — |
| 12.03 | [OSVVM i UVVM: metodologie dla VHDL](12.03-osvvm-i-uvvm-metodologie-dla-vhdl.md) | VHDL · Verilog · SystemVerilog | — |
| 12.04 | [Verilator: szybka symulacja z C++](12.04-verilator-szybka-symulacja-z-c.md) | Python / inne | — |
| 12.05 | [Modele w Pythonie i porównanie bit w bit](12.05-modele-w-pythonie-i-porownanie-bit-w-bit.md) | Python / inne | — |
| 12.06 | [Ciągła integracja projektu HDL w GitHub Actions](12.06-ciagla-integracja-projektu-hdl-w-github-actions.md) | — | — |

## Po tym module potrafisz

- pisać testy w cocotb i porównywać wyniki z modelem w numpy,
- organizować testy jednostkowe w VUnit,
- korzystać z bibliotek OSVVM i UVVM w testbenchach VHDL,
- przyspieszyć symulację Verilatorem,
- uruchamiać regresję w ciągłej integracji.

## Układ weryfikowany w module

**`fir8`** — filtr FIR o 8 współczynnikach w arytmetyce stałoprzecinkowej: wejście 12 bitów ze znakiem ze strumieniem `in_valid`, współczynniki Q1.15 (dolnoprzepustowe, symetryczne, wzmocnienie 1 dla składowej stałej), wyjście 16 bitów z zaokrągleniem połówki w górę i nasyceniem, potok 3 takty. Parametr `BUG` wstrzykuje błąd: `1` — obcięcie zamiast zaokrąglenia (1 LSB), `2` — brak nasycenia. Specyfikacja arytmetyki: [12.05](12.05-modele-w-pythonie-i-porownanie-bit-w-bit.md).

## Kod w module

- `hdl/` — układ `fir8` i jego prosty, samosprawdzający się testbench w trzech językach (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [model/fir_model.py](model/fir_model.py) — model w numpy: dokładny co do bitu i zmiennoprzecinkowy.
- [cocotb/](cocotb/) — testy w Pythonie i runner dla Icarusa, GHDL i Verilatora ([12.01](12.01-cocotb-testbench-w-pythonie.md)).
- [vunit/](vunit/) — testbench VUnit i skrypt `run.py`, który uruchamia też testbenche [osvvm/](osvvm/) i [uvvm/](uvvm/) ([12.02](12.02-vunit-testy-jednostkowe-dla-vhdl-i.md), [12.03](12.03-osvvm-i-uvvm-metodologie-dla-vhdl.md)).
- [verilator/](verilator/) — testbench C++ i porównanie szybkości symulatorów ([12.04](12.04-verilator-szybka-symulacja-z-c.md)).
- [requirements.txt](requirements.txt) — wersje pakietów Pythona; w CI zadanie *Weryfikacja open source* ([12.06](12.06-ciagla-integracja-projektu-hdl-w-github-actions.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
