# 22 — Wejścia-wyjścia i szybkie interfejsy

> **Część V** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 14 h

## Po co ten moduł

Styk FPGA ze światem zewnętrznym: standardy I/O, rejestry DDR, LVDS i serializacja, a na koniec nadajniki-odbiorniki wielogigabitowe i protokoły takie jak PCIe i JESD204. MAX 10 nie ma transceiverów, więc tę część omawiamy na przykładach innych rodzin.

## Wymagane wcześniej

[14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md), [15 — Zegary, reset i przejścia między domenami (CDC)](../15-zegary-reset-cdc/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 22.01 | [Standardy I/O, terminacja, siła sterowania i slew rate](22.01-standardy-i-o-terminacja-sila-sterowania-i-slew.md) | — | 🛠️ |
| 22.02 | [Rejestry DDR w I/O i interfejsy źródłowo-synchroniczne](22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 22.03 | [LVDS i serializacja (SERDES)](22.03-lvds-i-serializacja-serdes.md) | VHDL · Verilog · SystemVerilog | — |
| 22.04 | [Transceivery wielogigabitowe: 8b/10b, 64b/66b i wyrównanie](22.04-transceivery-wielogigabitowe-8b-10b-64b-66b-i.md) | Python | — |
| 22.05 | [Przegląd protokołów: PCIe, JESD204, Aurora, SATA](22.05-przeglad-protokolow-pcie-jesd204-aurora-sata.md) | — | — |
| 22.06 | [FPGA na płytce PCB: zasilanie, sekwencjonowanie i planowanie pinów](22.06-fpga-na-plytce-pcb-zasilanie-sekwencjonowanie-i.md) | — | — |

## Po tym module potrafisz

- dobrać standard I/O, terminację i siłę sterowania,
- opisać interfejs źródłowo-synchroniczny z rejestrami DDR,
- zaprojektować łącze LVDS z serializacją,
- wyjaśnić kodowanie 8b/10b i 64b/66b oraz wyrównanie kanałów,
- zaplanować piny i zasilanie FPGA na płytce PCB.

## Układy w module

- **`ddr_wyj`, `ddr_wej`, `zs_nadajnik`, `zs_odbiornik`** — modele rejestrów DDR bloku I/O i łącze źródłowo-synchroniczne z zegarem przesyłanym obok danych ([22.02](22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md)).
- **`prbs7`, `prbs7_spr`** — generator i samosynchronizujący się kontroler PRBS7, N bitów na takt ([22.02](22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md), [22.03](22.03-lvds-i-serializacja-serdes.md)).
- **`ser_tx`, `deser_rx`, `wyrownaj`** — serializator 8:1, deserializator z bitslipem i automat wyrównania słowa wzorcem treningowym ([22.03](22.03-lvds-i-serializacja-serdes.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)); `tb_ddr` mierzy okno danych z monitorem t_SU/t_H, `tb_serdes` — wyrównanie dla opóźnień 0–7 bitów.
- [kodowanie/kodowanie.py](kodowanie/kodowanie.py) — model 8b/10b (tablice, nierównowaga, przecinek) i 64b/66b (nagłówek, skrambler x⁵⁸ + x³⁹ + 1) ze sprawdzeniem własności; uruchamiany w CI ([22.04](22.04-transceivery-wielogigabitowe-8b-10b-64b-66b-i.md)).
- [deca/io/](deca/io/) — cztery wyjścia z różną siłą i slew rate, zegar i dane DDR (ALTDDIO_OUT/IN), pętla przez zworę z kontrolerem PRBS; `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl).
- CI: testbenche, lint, synteza i kompilacja modułu DECA w zadaniach ogólnych; `kodowanie.py` w zadaniu *Analiza czasowa, CDC, wydajność i debug* w [checks.yml](../../.github/workflows/checks.yml).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 22.01 Standardy I/O, terminacja, siła sterowania i slew rate
- [ ] 22.02 Rejestry DDR w I/O i interfejsy źródłowo-synchroniczne
- [ ] 22.03 LVDS i serializacja (SERDES)
- [ ] 22.04 Transceivery wielogigabitowe: 8b/10b, 64b/66b i wyrównanie
- [ ] 22.05 Przegląd protokołów: PCIe, JESD204, Aurora, SATA
- [ ] 22.06 FPGA na płytce PCB: zasilanie, sekwencjonowanie i planowanie pinów
