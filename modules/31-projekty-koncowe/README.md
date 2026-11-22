# 31 — Projekty końcowe na DECA

> **Część VII** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** DECA · **Szacowany czas:** ok. 60 h

## Po co ten moduł

Sześć większych projektów, które łączą wiedzę z całej bazy i nadają się do portfolio. Każdy ma specyfikację, architekturę, plan weryfikacji, implementację na DECA i listę rozszerzeń.

## Wymagane wcześniej

[20 — Interfejsy szeregowe niskiej szybkości](../20-interfejsy-szeregowe/README.md), [24 — Wideo i grafika](../24-wideo-i-grafika/README.md), [27 — Procesory w FPGA i systemy SoC](../27-procesory-i-soc/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 31.01 | [Projekt 1: zegar i stoper sterowany komendami przez UART](31.01-projekt-1-zegar-i-stoper-sterowany-komendami.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 31.02 | [Projekt 2: oscyloskop na wbudowanym ADC z obrazem przez HDMI](31.02-projekt-2-oscyloskop-na-wbudowanym-adc-z.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 31.03 | [Projekt 3: syntezator dźwięku sterowany przez UART lub MIDI](31.03-projekt-3-syntezator-dzwieku-sterowany-przez.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 31.04 | [Projekt 4: system z Nios V, DDR3 i strumieniem UDP](31.04-projekt-4-system-z-nios-v-ddr3-i-strumieniem-udp.md) | VHDL · Verilog · SystemVerilog · C | 🛠️ |
| 31.05 | [Projekt 5: przetwarzanie obrazu z kamery MIPI w czasie rzeczywistym](31.05-projekt-5-przetwarzanie-obrazu-z-kamery-mipi-w.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 31.06 | [Projekt 6: własny procesor RISC-V z peryferiami](31.06-projekt-6-wlasny-procesor-risc-v-z-peryferiami.md) | VHDL · Verilog · SystemVerilog · asembler | 🛠️ |

## Po tym module potrafisz

- przejść pełny cykl projektu: specyfikacja, architektura, RTL, weryfikacja, implementacja, uruchomienie,
- pokazać na rozmowie kwalifikacyjnej działające projekty z dokumentacją.

## Układy w module

| Projekt | Bloki własne | Bloki z wcześniejszych modułów | Testbench (wynik w CI) | DECA |
|---|---|---|---|---|
| 31.01 zegar | `zegar_stoper`, `komendy`, `projekt_zegar` | `uart_rx`, `uart_tx` (20) | `tb_projekt_zegar` — komendy, północ, błędy, stoper ±1 setna | [deca/zegar](deca/zegar/deca_top.v) |
| 31.02 oscyloskop | `zrzut`, `ram_2z`, `ekran_osc`, `oscyloskop` | `takt_wideo`, `adv7513_konfig` (24), `adc_sekwencer` (20) | `tb_oscyloskop` — każdy piksel ramki z modelem | [deca/oscyloskop](deca/oscyloskop/README.md) |
| 31.03 syntezator | `midi_parser`, `syntezator`, `projekt_syntezator` | `uart_rx` (20), `i2s_master`, `i2c_zapisy` (25), `sin_tab` (26) | `tb_projekt_syntezator` — częstotliwość, głosy, słowa I2S | [deca/syntezator](deca/syntezator/deca_top.v) |
| 31.04 UDP z DMA | `udp_dma` + sterownik C | `udp_nad`, `mii_tx`, `mii_rx` (25), `async_fifo`, `sync_bit` (15) | `tb_udp_dma` — pamięć z losowym `waitrequest`, 3 ramki z FCS | [deca/udp_ddr3](deca/udp_ddr3/README.md) |
| 31.05 obraz | `wzor_bayer`, `demozaika`, `isp`, `projekt_obraz` | `takt_wideo`, `filtr3x3`, `adv7513_konfig` (24) | `tb_projekt_obraz` — 5 trybów z modelem sceny | [deca/obraz](deca/obraz/deca_top.v) |
| 31.06 mikrokontroler | `rv_mcu`, `program/mcu.S`, `program/zloz.py` | `rv_potok` i reszta rdzenia, `pwm_avl` (27), UART (20) | `tb_rv_mcu` — program na rdzeniu: UART, PWM, LED | [deca/rv_mcu](deca/rv_mcu/deca_top.v) |

Bloki z wcześniejszych modułów są skopiowane do `hdl/`, żeby każdy projekt kompilował się samodzielnie. Projekty DECA nie były kompilowane w Quartusie — CI kompiluje moduły `deca_top` w symulatorach w wariancie bez rdzeni IP.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`), dane (`hdl/dane/mcu_sym.hex`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `program/` — program mikrokontrolera z 31.06 (`mcu.S`) i skrypt `zloz.py`, który składa go asemblerem z modułu 27 (`--sprawdz` w CI).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)); w `deca/udp_ddr3` także system Platform Designer (`system.tcl`) i program w C.

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 31.01 Projekt 1: zegar i stoper sterowany komendami przez UART
- [ ] 31.02 Projekt 2: oscyloskop na wbudowanym ADC z obrazem przez HDMI
- [ ] 31.03 Projekt 3: syntezator dźwięku sterowany przez UART lub MIDI
- [ ] 31.04 Projekt 4: system z Nios V, DDR3 i strumieniem UDP
- [ ] 31.05 Projekt 5: przetwarzanie obrazu z kamery MIPI w czasie rzeczywistym
- [ ] 31.06 Projekt 6: własny procesor RISC-V z peryferiami
