# 27 — Procesory w FPGA i systemy SoC

> **Część VI** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 22 h

## Po co ten moduł

Procesor w FPGA: miękki rdzeń Nios V na DECA, własne peryferia ze sterownikiem w C, otwarte rdzenie RISC-V, układy SoC z twardym procesorem i Linux. Moduł kończy się projektem własnego procesora RISC-V.

## Wymagane wcześniej

[21 — Magistrale i interfejsy na chipie](../21-magistrale-on-chip/README.md), [23 — Pamięci zewnętrzne](../23-pamieci-zewnetrzne/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 27.01 | [Procesor w FPGA: miękki czy twardy](27.01-procesor-w-fpga-miekki-czy-twardy.md) | — | — |
| 27.02 | [Nios V (RISC-V) w Platform Designer na DECA](27.02-nios-v-risc-v-w-platform-designer-na-deca.md) | — | 🛠️ |
| 27.03 | [Własny peryferial z rejestrami i sterownik w C](27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md) | VHDL · Verilog · SystemVerilog · C | 🛠️ |
| 27.04 | [Otwarte rdzenie RISC-V: PicoRV32, VexRiscv, NEORV32 i LiteX](27.04-otwarte-rdzenie-risc-v-picorv32-vexriscv.md) | — | 🛠️ |
| 27.05 | [Układy SoC z twardym procesorem: Zynq, Cyclone V SoC, Agilex](27.05-uklady-soc-z-twardym-procesorem-zynq-cyclone-v.md) | — | — |
| 27.06 | [Linux na FPGA i podział sprzęt–oprogramowanie](27.06-linux-na-fpga-i-podzial-sprzetoprogramowanie.md) | — | — |
| 27.07 | [Własny procesor RISC-V: od jednocyklowego do potokowego](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md) | VHDL · Verilog · SystemVerilog · Python | 🛠️ |

## Po tym module potrafisz

- zdecydować, kiedy użyć procesora miękkiego, a kiedy twardego,
- zbudować system Nios V w Platform Designer i uruchomić program w C,
- napisać własny peryferial z rejestrami i sterownik,
- użyć otwartych rdzeni RISC-V i LiteX,
- zaprojektować procesor RISC-V jednocyklowy i potokowy.

## Układy w module

- **`pwm_avl`** — peryferium PWM ze slave'em Avalon-MM: rejestry STER, OKRES, WYPELN, STATUS (W1C), rejestry cienia (zmiana od następnego okresu), przerwanie poziomem; komponent Platform Designer `pwm_avl_hw.tcl` i sterownik w C `pwm.h`/`pwm.c` wspólny dla Nios V i własnego SoC ([27.03](27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md)).
- **`rv_jedno`** — rdzeń RV32I jednocyklowy (CPI = 1, pamięć z odczytem kombinacyjnym) ([27.07](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md)).
- **`rv_potok`** — rdzeń RV32I z potokiem IF–ID–EX–MEM–WB dla pamięci blokowej: przekazywanie MEM/WB → EX, wstrzymanie load-use, skoki w EX z 2 taktami kary ([27.07](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md)).
- Wspólne bloki rdzeni: **`rv_dekoder`**, **`rv_alu`**, **`rv_rejestry`**, **`rv_wyrownanie`**.
- **`rv_soc`** — `rv_potok` + pamięć dwuportowa (program i dane) + rejestry systemowe (LED, liczniki, KONSOLA, TOHOST) + `pwm_avl` ([27.03](27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md), [27.07](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)): `tb_pwm` (zadania mastera Avalon-MM), `tb_rv_jedno` i `tb_rv_soc` — program testowy RV32I, każdy zapis rdzenia porównany z zapisem symulatora ISS (226 zapisów, 0 niezgodności), CPI 1,000 i 1,448; `hdl/dane/` — obraz programu i ślad ISS.
- [program/](program/) — [rvasm.py](program/rvasm.py): asembler i symulator RV32I (biblioteka standardowa Pythona; `--sprawdz` w CI), [test.S](program/test.S) — program testowy rdzeni, [deca.S](program/deca.S) — program dla płytki; [program/c](program/c) — program w C (kod startowy, skrypt konsolidatora, sterownik PWM, CRC-32) kompilowany w CI pakietem `gcc-riscv64-unknown-elf` i uruchamiany na `rv_soc` w Icarusie.
- [deca/rv/](deca/rv/) — własny SoC na DECA: rdzeń potokowy, 8 KB pamięci M9K z programem `deca.S`, licznik na LED[6:0] i PWM na LED[7] ([27.07](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md)); `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- [deca/niosv/](deca/niosv/) — system Nios V w Platform Designer ze skryptu (`system.tcl`), komponent `pwm_avl_hw.tcl`, program w C z przerwaniem PWM, kroki BSP i aplikacji w [README](deca/niosv/README.md) ([27.02](27.02-nios-v-risc-v-w-platform-designer-na-deca.md)).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

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
