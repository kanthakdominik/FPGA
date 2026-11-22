# 23 — Pamięci zewnętrzne

> **Część V** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 16 h

## Po co ten moduł

Jak działają pamięci SDRAM i DDR i jak korzysta się z nich w FPGA. Na DECA uruchomisz kontroler DDR3 (UniPHY), pamięć QSPI i kartę microSD.

## Wymagane wcześniej

[15 — Zegary, reset i przejścia między domenami (CDC)](../15-zegary-reset-cdc/README.md), [21 — Magistrale i interfejsy na chipie](../21-magistrale-on-chip/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 23.01 | [SDRAM i DDR: jak działają, odświeżanie i opóźnienia](23.01-sdram-i-ddr-jak-dzialaja-odswiezanie-i.md) | — | — |
| 23.02 | [Kontroler DDR3 na MAX 10 (UniPHY)](23.02-kontroler-ddr3-na-max-10-uniphy.md) | — | 🛠️ |
| 23.03 | [Pamięci QSPI flash i HyperRAM](23.03-pamieci-qspi-flash-i-hyperram.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 23.04 | [Arbitraż dostępu do pamięci i DMA](23.04-arbitraz-dostepu-do-pamieci-i-dma.md) | VHDL · Verilog · SystemVerilog | — |
| 23.05 | [Karta microSD: tryb SPI i tryb SD](23.05-karta-microsd-tryb-spi-i-tryb-sd.md) | VHDL · Verilog · SystemVerilog | 🛠️ |

## Po tym module potrafisz

- opisać działanie DDR: banki, wiersze, odświeżanie, opóźnienia,
- skonfigurować i uruchomić kontroler DDR3 na MAX 10,
- obsłużyć pamięć QSPI flash i HyperRAM,
- zaprojektować arbitraż i DMA do pamięci,
- odczytywać i zapisywać kartę microSD.

## Układy w module

- **`qspi_master`** — kontroler pamięci SPI/QSPI flash: rozkaz, adres 24 b, cykle puste, dane 1-bitowo albo 4-bitowo, zapis i odczyt, tryb SPI 0 ([23.03](23.03-pamieci-qspi-flash-i-hyperram.md)).
- **`arbiter_rr`** — arbiter round-robin N masterów Avalon-MM z odczytami potokowymi i kolejką kierującą `readdatavalid` ([23.04](23.04-arbitraz-dostepu-do-pamieci-i-dma.md)).
- **`dma_kopia`** — DMA pamięć → pamięć z wieloma odczytami w toku i kolejką danych ([23.04](23.04-arbitraz-dostepu-do-pamieci-i-dma.md)).
- **`sd_spi`** — kontroler karty SD w trybie SPI: inicjalizacja SDSC/SDHC z CRC7 i kodami błędów, odczyt bloku 512 B z kontrolą CRC16 ([23.05](23.05-karta-microsd-tryb-spi-i-tryb-sd.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)); `tb_qspi` z modelem pamięci flash (WREN, WIP, strony, quad), `tb_dma` z trzema masterami i losowym `waitrequest`, `tb_sd` z modelem karty SDHC i SDSC.
- [deca/qspi/](deca/qspi/) — odczyt ID i porównanie odczytów 1-1-1 i 1-1-4 z pamięci QSPI płytki (bez zapisu); [deca/sd/](deca/sd/) — inicjalizacja karty microSD i odczyt bloku 0 z sygnaturą 0x55AA; `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- [deca/ddr3/](deca/ddr3/README.md) — kroki generacji kontrolera DDR3 (UniPHY) z projektem przykładowym i generatorem ruchu (bez kodu w repozytorium; wymaga Quartusa, poza CI).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 23.01 SDRAM i DDR: jak działają, odświeżanie i opóźnienia
- [ ] 23.02 Kontroler DDR3 na MAX 10 (UniPHY)
- [ ] 23.03 Pamięci QSPI flash i HyperRAM
- [ ] 23.04 Arbitraż dostępu do pamięci i DMA
- [ ] 23.05 Karta microSD: tryb SPI i tryb SD
