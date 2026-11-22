# 26 — Cyfrowe przetwarzanie sygnałów w FPGA

> **Część VI** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 20 h

## Po co ten moduł

Implementacja algorytmów DSP w sprzęcie: filtry FIR i IIR, generatory NCO, decymacja i interpolacja, FFT oraz przetwarzanie I/Q. Kluczowa umiejętność to przejście od modelu w Pythonie do RTL z weryfikacją bit w bit.

## Wymagane wcześniej

[19 — Arytmetyka i liczby w sprzęcie](../19-arytmetyka/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 26.01 | [Filtry FIR: struktury bezpośrednia, transponowana, symetryczna i systoliczna](26.01-filtry-fir-struktury-bezposrednia-transponowana.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 26.02 | [Filtry IIR i stabilność w arytmetyce stałoprzecinkowej](26.02-filtry-iir-i-stabilnosc-w-arytmetyce.md) | VHDL · Verilog · SystemVerilog | — |
| 26.03 | [Generatory NCO i DDS](26.03-generatory-nco-i-dds.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 26.04 | [Decymacja i interpolacja: CIC i filtry wielofazowe](26.04-decymacja-i-interpolacja-cic-i-filtry.md) | VHDL · Verilog · SystemVerilog | — |
| 26.05 | [FFT w sprzęcie](26.05-fft-w-sprzecie.md) | VHDL · Verilog · SystemVerilog | — |
| 26.06 | [Przetwarzanie I/Q i radio programowalne](26.06-przetwarzanie-i-q-i-radio-programowalne.md) | VHDL · Verilog · SystemVerilog | — |
| 26.07 | [Od modelu w Pythonie do RTL — weryfikacja bit w bit](26.07-od-modelu-w-pythonie-do-rtl-weryfikacja-bit-w.md) | Python / inne | — |

## Po tym module potrafisz

- zaimplementować filtr FIR w kilku strukturach i ocenić ich koszt,
- zaimplementować stabilny filtr IIR w arytmetyce stałoprzecinkowej,
- zaprojektować NCO, filtr CIC i filtr wielofazowy,
- użyć i zweryfikować rdzeń FFT,
- przejść od modelu w Pythonie do RTL z porównaniem bit w bit.

## Układy w module

- **`fir_transp`, `fir_sym`** — filtr FIR 31 współczynników Q1.15 w strukturze transponowanej (opóźnienie 1 takt) i symetrycznej z sumatorem wstępnym i potokiem (16 mnożarek, 5 taktów); współczynniki z portu ([26.01](26.01-filtry-fir-struktury-bezposrednia-transponowana.md)).
- **`biquad_df2t`** — biquad w postaci transponowanej II, jedna próbka na takt, stany 40-bitowe, trzy tryby kwantyzacji w pętli (floor, zaokrąglenie, w stronę zera) i nasycenie ([26.02](26.02-filtry-iir-i-stabilnosc-w-arytmetyce.md)).
- **`nco`, `sin_tab`, `sd_dac`** — generator NCO z 32-bitowym akumulatorem fazy i ćwiartką sinusa (256 słów) dla sin i cos; przetwornik sigma-delta pierwszego rzędu na jeden pin ([26.03](26.03-generatory-nco-i-dds.md)).
- **`cic_dec`, `pf_dec`** — decymator CIC (N = 3, R = 8, 25 bitów, bez mnożarek) i decymator FIR przez 4 z jedną mnożarką i buforem kołowym ([26.04](26.04-decymacja-i-interpolacja-cic-i-filtry.md)).
- **`fft64`, `tw_tab`** — FFT 64 punktów radix-2 w miejscu: wczytanie z odwróceniem bitów, 192 motyle po jednym na takt, skalowanie ½ na etap, wynik w kolejności naturalnej ([26.05](26.05-fft-w-sprzecie.md)).
- **`ddc`** — przemiana w dół: NCO, mieszanie I/Q z zaokrągleniem i dwa decymatory CIC ([26.06](26.06-przetwarzanie-i-q-i-radio-programowalne.md)).

## Kod w module

- [model/dsp_model.py](model/dsp_model.py) — model bit w bit wszystkich układów (biblioteka standardowa Pythona): projekt i kwantyzacja współczynników, moduły ROM `sin_tab` i `tw_tab` generowane w trzech językach, wektory testowe w `hdl/dane/` i miary jakości (charakterystyka FIR, cykle graniczne, SFDR, błąd FFT); `--sprawdz` w CI kontroluje zgodność plików w repozytorium z modelem ([26.07](26.07-od-modelu-w-pythonie-do-rtl-weryfikacja-bit-w.md)).
- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)): `tb_fir`, `tb_iir`, `tb_nco`, `tb_dec`, `tb_fft`, `tb_ddc` — każdy czyta wektory z `hdl/dane/*.hex` i porównuje wyniki z modelem bit w bit, niezależnie od opóźnienia; w VHDL wspólne funkcje w `dsp_pkg` i czytanie plików w `wektory_pkg`.
- [deca/dsp/](deca/dsp/) — NCO → filtr FIR → dwa przetworniki sigma-delta na złączu GPIO0 (sygnał po filtrze i przed filtrem), częstotliwości z KEY[1], przemiatanie i fala prostokątna z przełączników ([26.01](26.01-filtry-fir-struktury-bezposrednia-transponowana.md), [26.03](26.03-generatory-nco-i-dds.md)); `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

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
