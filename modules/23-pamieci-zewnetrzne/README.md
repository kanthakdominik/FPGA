# 23 — Pamięci zewnętrzne

> **Część V** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Jak działają pamięci SDRAM i DDR i jak korzysta się z nich w FPGA. Na DECA uruchomisz kontroler DDR3 (UniPHY), pamięć QSPI i kartę microSD.

## Wymagane wcześniej

[15 — Zegary, reset i przejścia między domenami (CDC)](../15-zegary-reset-cdc/README.md), [21 — Magistrale i interfejsy na chipie](../21-magistrale-on-chip/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 23.01 | [SDRAM i DDR: jak działają, odświeżanie i opóźnienia](23.01-sdram-i-ddr-jak-dzialaja-odswiezanie-i.md) | — | — | 🔲 |
| 23.02 | [Kontroler DDR3 na MAX 10 (UniPHY)](23.02-kontroler-ddr3-na-max-10-uniphy.md) | — | 🛠️ | 🔲 |
| 23.03 | [Pamięci QSPI flash i HyperRAM](23.03-pamieci-qspi-flash-i-hyperram.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 23.04 | [Arbitraż dostępu do pamięci i DMA](23.04-arbitraz-dostepu-do-pamieci-i-dma.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 23.05 | [Karta microSD: tryb SPI i tryb SD](23.05-karta-microsd-tryb-spi-i-tryb-sd.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |

## Po tym module potrafisz

- opisać działanie DDR: banki, wiersze, odświeżanie, opóźnienia,
- skonfigurować i uruchomić kontroler DDR3 na MAX 10,
- obsłużyć pamięć QSPI flash i HyperRAM,
- zaprojektować arbitraż i DMA do pamięci,
- odczytywać i zapisywać kartę microSD.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 23.01 SDRAM i DDR: jak działają, odświeżanie i opóźnienia
- [ ] 23.02 Kontroler DDR3 na MAX 10 (UniPHY)
- [ ] 23.03 Pamięci QSPI flash i HyperRAM
- [ ] 23.04 Arbitraż dostępu do pamięci i DMA
- [ ] 23.05 Karta microSD: tryb SPI i tryb SD
