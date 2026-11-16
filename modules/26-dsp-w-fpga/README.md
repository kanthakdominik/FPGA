# 26 — Cyfrowe przetwarzanie sygnałów w FPGA

> **Część VI** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 20 h · **Status:** 🔲 szkielet

## Po co ten moduł

Implementacja algorytmów DSP w sprzęcie: filtry FIR i IIR, generatory NCO, decymacja i interpolacja, FFT oraz przetwarzanie I/Q. Kluczowa umiejętność to przejście od modelu w Pythonie do RTL z weryfikacją bit w bit.

## Wymagane wcześniej

[19 — Arytmetyka i liczby w sprzęcie](../19-arytmetyka/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 26.01 | [Filtry FIR: struktury bezpośrednia, transponowana, symetryczna i systoliczna](26.01-filtry-fir-struktury-bezposrednia-transponowana.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 26.02 | [Filtry IIR i stabilność w arytmetyce stałoprzecinkowej](26.02-filtry-iir-i-stabilnosc-w-arytmetyce.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 26.03 | [Generatory NCO i DDS](26.03-generatory-nco-i-dds.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 26.04 | [Decymacja i interpolacja: CIC i filtry wielofazowe](26.04-decymacja-i-interpolacja-cic-i-filtry.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 26.05 | [FFT w sprzęcie](26.05-fft-w-sprzecie.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 26.06 | [Przetwarzanie I/Q i radio programowalne](26.06-przetwarzanie-i-q-i-radio-programowalne.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 26.07 | [Od modelu w Pythonie do RTL — weryfikacja bit w bit](26.07-od-modelu-w-pythonie-do-rtl-weryfikacja-bit-w.md) | Python / inne | — | 🔲 |

## Po tym module potrafisz

- zaimplementować filtr FIR w kilku strukturach i ocenić ich koszt,
- zaimplementować stabilny filtr IIR w arytmetyce stałoprzecinkowej,
- zaprojektować NCO, filtr CIC i filtr wielofazowy,
- użyć i zweryfikować rdzeń FFT,
- przejść od modelu w Pythonie do RTL z porównaniem bit w bit.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 26.01 Filtry FIR: struktury bezpośrednia, transponowana, symetryczna i systoliczna
- [ ] 26.02 Filtry IIR i stabilność w arytmetyce stałoprzecinkowej
- [ ] 26.03 Generatory NCO i DDS
- [ ] 26.04 Decymacja i interpolacja: CIC i filtry wielofazowe
- [ ] 26.05 FFT w sprzęcie
- [ ] 26.06 Przetwarzanie I/Q i radio programowalne
- [ ] 26.07 Od modelu w Pythonie do RTL — weryfikacja bit w bit
