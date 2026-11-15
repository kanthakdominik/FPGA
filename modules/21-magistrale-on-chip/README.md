# 21 — Magistrale i interfejsy na chipie

> **Część V** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL, weryfikacja · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Jak bloki w dużym projekcie rozmawiają ze sobą: strumienie AXI4-Stream i Avalon-ST, rejestry AXI4-Lite i Avalon-MM, transfery z burstami i otwarta magistrala Wishbone. Moduł pokazuje też generowanie map rejestrów i narzędzia do składania systemu.

## Wymagane wcześniej

[08 — Automaty stanów i sterowanie](../08-automaty-stanow/README.md), [18 — Pamięci w FPGA](../18-pamieci/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 21.01 | [Strumienie z handshakiem: AXI4-Stream i Avalon-ST](21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 21.02 | [Rejestry sterujące: AXI4-Lite i Avalon-MM](21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 21.03 | [AXI4 i Avalon-MM z burstami](21.03-axi4-i-avalon-mm-z-burstami.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 21.04 | [Wishbone i magistrale otwarte](21.04-wishbone-i-magistrale-otwarte.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 21.05 | [Mapa rejestrów i generatory: SystemRDL, PeakRDL](21.05-mapa-rejestrow-i-generatory-systemrdl-peakrdl.md) | Python / inne | — | 🔲 |
| 21.06 | [Platform Designer i IP Integrator](21.06-platform-designer-i-ip-integrator.md) | — | 🛠️ | 🔲 |

## Po tym module potrafisz

- zaprojektować blok strumieniowy zgodny z AXI4-Stream i Avalon-ST,
- zaprojektować slave AXI4-Lite i Avalon-MM z mapą rejestrów,
- opisać transfery z burstami i kanały AXI4,
- generować mapę rejestrów z opisu SystemRDL,
- składać system w Platform Designer.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 21.01 Strumienie z handshakiem: AXI4-Stream i Avalon-ST
- [ ] 21.02 Rejestry sterujące: AXI4-Lite i Avalon-MM
- [ ] 21.03 AXI4 i Avalon-MM z burstami
- [ ] 21.04 Wishbone i magistrale otwarte
- [ ] 21.05 Mapa rejestrów i generatory: SystemRDL, PeakRDL
- [ ] 21.06 Platform Designer i IP Integrator
