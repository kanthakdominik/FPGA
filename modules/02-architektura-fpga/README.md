# 02 — Architektura układów FPGA

> **Część I** · **Oznaczenia:** 🟢🛠️💼 · **Ścieżki:** RTL, weryfikacja, DECA · **Szacowany czas:** ok. 12 h

## Po co ten moduł

Co naprawdę jest w środku układu FPGA i dlaczego to wpływa na sposób pisania kodu. Moduł opisuje bloki logiczne, pamięci, DSP, zegary i wejścia-wyjścia na przykładzie MAX 10 i porównuje go z rodzinami innych producentów.

## Wymagane wcześniej

[01 — Logika cyfrowa dla projektanta FPGA](../01-logika-cyfrowa/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 02.01 | [Od PAL i CPLD do FPGA — ewolucja układów programowalnych](02.01-od-pal-i-cpld-do-fpga-ewolucja-ukladow.md) | — | — |
| 02.02 | [LUT, przerzutnik i blok logiczny: LE, ALM, CLB, slice](02.02-lut-przerzutnik-i-blok-logiczny-le-alm-clb-slice.md) | — | — |
| 02.03 | [Łańcuchy przeniesień i logika arytmetyczna](02.03-lancuchy-przeniesien-i-logika-arytmetyczna.md) | — | — |
| 02.04 | [Sieć połączeń i dlaczego trasowanie kosztuje czas](02.04-siec-polaczen-i-dlaczego-trasowanie-kosztuje.md) | — | — |
| 02.05 | [Bloki pamięci i pamięć rozproszona](02.05-bloki-pamieci-i-pamiec-rozproszona.md) | — | — |
| 02.06 | [Bloki DSP i mnożarki sprzętowe](02.06-bloki-dsp-i-mnozarki-sprzetowe.md) | — | — |
| 02.07 | [Zegary: sieci globalne, PLL i MMCM](02.07-zegary-sieci-globalne-pll-i-mmcm.md) | — | — |
| 02.08 | [Bloki wejścia-wyjścia i banki I/O](02.08-bloki-wejscia-wyjscia-i-banki-i-o.md) | — | — |
| 02.09 | [Konfiguracja: SRAM, flash, antifuse — MAX 10 jako FPGA z wbudowaną pamięcią flash](02.09-konfiguracja-sram-flash-antifuse-max-10-jako.md) | — | 🛠️ `blink` |
| 02.10 | [Przegląd rynku: AMD, Altera, Lattice, Microchip, Gowin, Efinix](02.10-przeglad-rynku-amd-altera-lattice-microchip.md) | — | — |

## Po tym module potrafisz

- opisać budowę bloku logicznego (LUT, przerzutnik, łańcuch przeniesień) w MAX 10 i w układach AMD,
- wskazać, które zasoby (M9K, mnożarki, PLL) wykorzysta dany fragment projektu,
- wyjaśnić, czym różni się konfiguracja SRAM, flash i antifuse i co z tego wynika dla MAX 10,
- porównać główne rodziny FPGA i dobrać układ do zastosowania.

## Kod w module

- Moduł nie ma własnego kodu HDL. Doświadczenie na płytce DECA w temacie 02.09 korzysta z projektu [blink](../00-srodowisko-pracy/deca/blink/) z modułu 00.

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 02.01 Od PAL i CPLD do FPGA — ewolucja układów programowalnych
- [ ] 02.02 LUT, przerzutnik i blok logiczny: LE, ALM, CLB, slice
- [ ] 02.03 Łańcuchy przeniesień i logika arytmetyczna
- [ ] 02.04 Sieć połączeń i dlaczego trasowanie kosztuje czas
- [ ] 02.05 Bloki pamięci i pamięć rozproszona
- [ ] 02.06 Bloki DSP i mnożarki sprzętowe
- [ ] 02.07 Zegary: sieci globalne, PLL i MMCM
- [ ] 02.08 Bloki wejścia-wyjścia i banki I/O
- [ ] 02.09 Konfiguracja: SRAM, flash, antifuse — MAX 10 jako FPGA z wbudowaną pamięcią flash
- [ ] 02.10 Przegląd rynku: AMD, Altera, Lattice, Microchip, Gowin, Efinix
