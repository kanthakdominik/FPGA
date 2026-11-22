# 21 — Magistrale i interfejsy na chipie

> **Część V** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, weryfikacja · **Szacowany czas:** ok. 16 h

## Po co ten moduł

Jak bloki w dużym projekcie rozmawiają ze sobą: strumienie AXI4-Stream i Avalon-ST, rejestry AXI4-Lite i Avalon-MM, transfery z burstami i otwarta magistrala Wishbone. Moduł pokazuje też generowanie map rejestrów i narzędzia do składania systemu.

## Wymagane wcześniej

[08 — Automaty stanów i sterowanie](../08-automaty-stanow/README.md), [18 — Pamięci w FPGA](../18-pamieci/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 21.01 | [Strumienie z handshakiem: AXI4-Stream i Avalon-ST](21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md) | VHDL · Verilog · SystemVerilog | — |
| 21.02 | [Rejestry sterujące: AXI4-Lite i Avalon-MM](21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 21.03 | [AXI4 i Avalon-MM z burstami](21.03-axi4-i-avalon-mm-z-burstami.md) | VHDL · Verilog · SystemVerilog | — |
| 21.04 | [Wishbone i magistrale otwarte](21.04-wishbone-i-magistrale-otwarte.md) | VHDL · Verilog · SystemVerilog | — |
| 21.05 | [Mapa rejestrów i generatory: SystemRDL, PeakRDL](21.05-mapa-rejestrow-i-generatory-systemrdl-peakrdl.md) | Python / inne | — |
| 21.06 | [Platform Designer i IP Integrator](21.06-platform-designer-i-ip-integrator.md) | — | 🛠️ |

## Po tym module potrafisz

- zaprojektować blok strumieniowy zgodny z AXI4-Stream i Avalon-ST,
- zaprojektować slave AXI4-Lite i Avalon-MM z mapą rejestrów,
- opisać transfery z burstami i kanały AXI4,
- generować mapę rejestrów z opisu SystemRDL,
- składać system w Platform Designer.

## Układy w module

- **`axis_skid`, `axis_8na32`** — bufor poślizgowy AXI4-Stream (ready z przerzutnika, 1 słowo/takt) i konwerter szerokości 8 → 32 z TKEEP i TLAST ([21.01](21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md)).
- **`rejestry_rdzen`, `axil_rejestry`, `avmm_rejestry`** — mapa rejestrów (ID, RW z maską bajtów, RO, W1C z przerwaniem i maską) niezależna od magistrali i adaptery AXI4-Lite oraz Avalon-MM ([21.02](21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md)).
- **`axi_ram`, `avmm_burst_ram`** — pamięci ze slave'ami AXI4 (FIXED, INCR, WRAP, WSTRB, ID) i Avalon-MM z burstami ([21.03](21.03-axi4-i-avalon-mm-z-burstami.md)).
- **`wb_ram`, `wb_rejestry`, `wb_dekoder`** — Wishbone B4 w trybie potokowym: pamięć ze STALL, rejestry, dekoder adresu z odpowiedzią ERR ([21.04](21.04-wishbone-i-magistrale-otwarte.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)); testbenche mają mastery z losowymi opóźnieniami kanałów i przeciwciśnieniem oraz modele pamięci liczone wprost ze wzorów specyfikacji.
- [rdl/](rdl/) — mapa rejestrów w SystemRDL ([rejestry.rdl](rdl/rejestry.rdl)), [sprawdz.py](rdl/sprawdz.py) (tabela rejestrów i zgodność z RTL), [generuj.sh](rdl/generuj.sh) (PeakRDL: blok SystemVerilog z AXI4-Lite, nagłówek C, HTML) — uruchamiane w CI.
- [deca/rejestry/](deca/rejestry/) — system Platform Designer (JTAG to Avalon Master Bridge + `avmm_rejestry`) ze skryptu [system.tcl](deca/rejestry/system.tcl), komponent [avmm_rejestry_hw.tcl](deca/rejestry/avmm_rejestry_hw.tcl), skrypt System Console [konsola.tcl](deca/rejestry/konsola.tcl); `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl).
- CI: testbenche, lint, synteza i kompilacja modułów DECA w zadaniach ogólnych; SystemRDL/PeakRDL w zadaniu *Weryfikacja open source* w [checks.yml](../../.github/workflows/checks.yml).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

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
