# 27 — Procesory w FPGA i systemy SoC

> **Część VI** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 22 h · **Status:** 🔲 szkielet

## Po co ten moduł

Procesor w FPGA: miękki rdzeń Nios V na DECA, własne peryferia ze sterownikiem w C, otwarte rdzenie RISC-V, układy SoC z twardym procesorem i Linux. Moduł kończy się projektem własnego procesora RISC-V.

## Wymagane wcześniej

[21 — Magistrale i interfejsy na chipie](../21-magistrale-on-chip/README.md), [23 — Pamięci zewnętrzne](../23-pamieci-zewnetrzne/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 27.01 | [Procesor w FPGA: miękki czy twardy](27.01-procesor-w-fpga-miekki-czy-twardy.md) | — | — | 🔲 |
| 27.02 | [Nios V (RISC-V) w Platform Designer na DECA](27.02-nios-v-risc-v-w-platform-designer-na-deca.md) | — | 🛠️ | 🔲 |
| 27.03 | [Własny peryferial z rejestrami i sterownik w C](27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 27.04 | [Otwarte rdzenie RISC-V: PicoRV32, VexRiscv, NEORV32 i LiteX](27.04-otwarte-rdzenie-risc-v-picorv32-vexriscv.md) | — | 🛠️ | 🔲 |
| 27.05 | [Układy SoC z twardym procesorem: Zynq, Cyclone V SoC, Agilex](27.05-uklady-soc-z-twardym-procesorem-zynq-cyclone-v.md) | — | — | 🔲 |
| 27.06 | [Linux na FPGA i podział sprzęt–oprogramowanie](27.06-linux-na-fpga-i-podzial-sprzetoprogramowanie.md) | — | — | 🔲 |
| 27.07 | [Własny procesor RISC-V: od jednocyklowego do potokowego](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |

## Po tym module potrafisz

- zdecydować, kiedy użyć procesora miękkiego, a kiedy twardego,
- zbudować system Nios V w Platform Designer i uruchomić program w C,
- napisać własny peryferial z rejestrami i sterownik,
- użyć otwartych rdzeni RISC-V i LiteX,
- zaprojektować procesor RISC-V jednocyklowy i potokowy.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 27.01 Procesor w FPGA: miękki czy twardy
- [ ] 27.02 Nios V (RISC-V) w Platform Designer na DECA
- [ ] 27.03 Własny peryferial z rejestrami i sterownik w C
- [ ] 27.04 Otwarte rdzenie RISC-V: PicoRV32, VexRiscv, NEORV32 i LiteX
- [ ] 27.05 Układy SoC z twardym procesorem: Zynq, Cyclone V SoC, Agilex
- [ ] 27.06 Linux na FPGA i podział sprzęt–oprogramowanie
- [ ] 27.07 Własny procesor RISC-V: od jednocyklowego do potokowego
