# 12 — Weryfikacja z otwartymi narzędziami

> **Część III** · **Oznaczenia:** 🔍 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Weryfikacja bez drogich licencji: cocotb (testy w Pythonie), VUnit, OSVVM i UVVM dla VHDL oraz Verilator. Te narzędzia działają w GitHub Actions i coraz częściej także w firmach.

## Wymagane wcześniej

[09 — Symulacja i testbenche](../09-symulacja-i-testbench/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 12.01 | [cocotb: testbench w Pythonie](12.01-cocotb-testbench-w-pythonie.md) | Python / inne | — | 🔲 |
| 12.02 | [VUnit: testy jednostkowe dla VHDL i SystemVeriloga](12.02-vunit-testy-jednostkowe-dla-vhdl-i.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 12.03 | [OSVVM i UVVM: metodologie dla VHDL](12.03-osvvm-i-uvvm-metodologie-dla-vhdl.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 12.04 | [Verilator: szybka symulacja z C++](12.04-verilator-szybka-symulacja-z-c.md) | Python / inne | — | 🔲 |
| 12.05 | [Modele w Pythonie i porównanie bit w bit](12.05-modele-w-pythonie-i-porownanie-bit-w-bit.md) | Python / inne | — | 🔲 |
| 12.06 | [Ciągła integracja projektu HDL w GitHub Actions](12.06-ciagla-integracja-projektu-hdl-w-github-actions.md) | — | — | 🔲 |

## Po tym module potrafisz

- pisać testy w cocotb i porównywać wyniki z modelem w numpy,
- organizować testy jednostkowe w VUnit,
- korzystać z bibliotek OSVVM i UVVM w testbenchach VHDL,
- przyspieszyć symulację Verilatorem,
- uruchamiać regresję w ciągłej integracji.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 12.01 cocotb: testbench w Pythonie
- [ ] 12.02 VUnit: testy jednostkowe dla VHDL i SystemVeriloga
- [ ] 12.03 OSVVM i UVVM: metodologie dla VHDL
- [ ] 12.04 Verilator: szybka symulacja z C++
- [ ] 12.05 Modele w Pythonie i porównanie bit w bit
- [ ] 12.06 Ciągła integracja projektu HDL w GitHub Actions
