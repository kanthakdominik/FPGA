# 22 — Wejścia-wyjścia i szybkie interfejsy

> **Część V** · **Oznaczenia:** 💼 · **Ścieżki:** RTL · **Szacowany czas:** ok. 14 h · **Status:** 🔲 szkielet

## Po co ten moduł

Styk FPGA ze światem zewnętrznym: standardy I/O, rejestry DDR, LVDS i serializacja, a na koniec nadajniki-odbiorniki wielogigabitowe i protokoły takie jak PCIe i JESD204. MAX 10 nie ma transceiverów, więc tę część omawiamy na przykładach innych rodzin.

## Wymagane wcześniej

[14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md), [15 — Zegary, reset i przejścia między domenami (CDC)](../15-zegary-reset-cdc/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 22.01 | [Standardy I/O, terminacja, siła sterowania i slew rate](22.01-standardy-i-o-terminacja-sila-sterowania-i-slew.md) | — | 🛠️ | 🔲 |
| 22.02 | [Rejestry DDR w I/O i interfejsy źródłowo-synchroniczne](22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 22.03 | [LVDS i serializacja (SERDES)](22.03-lvds-i-serializacja-serdes.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 22.04 | [Transceivery wielogigabitowe: 8b/10b, 64b/66b i wyrównanie](22.04-transceivery-wielogigabitowe-8b-10b-64b-66b-i.md) | — | — | 🔲 |
| 22.05 | [Przegląd protokołów: PCIe, JESD204, Aurora, SATA](22.05-przeglad-protokolow-pcie-jesd204-aurora-sata.md) | — | — | 🔲 |
| 22.06 | [FPGA na płytce PCB: zasilanie, sekwencjonowanie i planowanie pinów](22.06-fpga-na-plytce-pcb-zasilanie-sekwencjonowanie-i.md) | — | — | 🔲 |

## Po tym module potrafisz

- dobrać standard I/O, terminację i siłę sterowania,
- opisać interfejs źródłowo-synchroniczny z rejestrami DDR,
- zaprojektować łącze LVDS z serializacją,
- wyjaśnić kodowanie 8b/10b i 64b/66b oraz wyrównanie kanałów,
- zaplanować piny i zasilanie FPGA na płytce PCB.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

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
