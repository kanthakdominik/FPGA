# 13 — Weryfikacja formalna

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 12 h

## Po co ten moduł

Dowodzenie poprawności zamiast szukania błędów przypadkowymi testami. Moduł używa SymbiYosys, Yosysa i wtyczki GHDL (wszystko w OSS CAD Suite), właściwości w SystemVerilogu i PSL dla VHDL, a przykłady obejmują licznik, ALU z handshakiem z modułu 10, FIFO i sprawdzanie równoważności po syntezie. Każdy dowód, każdy oczekiwany kontrprzykład i każdy cover jest sprawdzany w CI.

## Wymagane wcześniej

[10 — Weryfikacja w SystemVerilogu](../10-weryfikacja-systemverilog/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 13.01 | [Dowód zamiast symulacji: BMC, indukcja i cover](13.01-dowod-zamiast-symulacji-bmc-indukcja-i-cover.md) | VHDL · Verilog · SystemVerilog | — |
| 13.02 | [SymbiYosys: pierwsze dowody](13.02-symbiyosys-pierwsze-dowody.md) | VHDL · SystemVerilog | — |
| 13.03 | [Pisanie właściwości: assume, assert, cover](13.03-pisanie-wlasciwosci-assume-assert-cover.md) | SystemVerilog | — |
| 13.04 | [Formalna weryfikacja FIFO i interfejsów z handshakiem](13.04-formalna-weryfikacja-fifo-i-interfejsow-z.md) | VHDL · Verilog · SystemVerilog | — |
| 13.05 | [Sprawdzanie równoważności i metody formalne w przemyśle](13.05-sprawdzanie-rownowaznosci-i-metody-formalne-w.md) | Python / inne | — |

## Po tym module potrafisz

- wyjaśnić BMC, indukcję i sprawdzanie osiągalności (cover),
- pisać założenia, asercje i cele pokrycia,
- udowodnić poprawność FIFO i protokołu valid/ready,
- opisać sprawdzanie równoważności i miejsce metod formalnych w przemyśle.

## Układ weryfikowany w module

- **`cnt10`** — licznik 0…9 z zezwoleniem i sygnałem przejścia 9 → 0; stany 10…15 nieosiągalne — najprostszy przykład, w którym k-indukcja potrzebuje niezmiennika ([13.01](13.01-dowod-zamiast-symulacji-bmc-indukcja-i-cover.md), [13.02](13.02-symbiyosys-pierwsze-dowody.md)).
- **`alu_hs`** z [modułu 10](../10-weryfikacja-systemverilog/README.md) — ALU z handshakiem valid/ready i dwoma wstrzykiwanymi błędami; formalnie: dowód dla `BUG=0`, kontrprzykłady dla `BUG=1` i `BUG=2` ([13.03](13.03-pisanie-wlasciwosci-assume-assert-cover.md)), równoważność RTL i netlisty ([13.05](13.05-sprawdzanie-rownowaznosci-i-metody-formalne-w.md)).
- **`fifo_sync`** — FIFO 8 × 8 z odczytem z wyprzedzeniem i wskaźnikami o bit szerszymi niż adres; właściwości wbudowane w RTL, śledzenie dowolnego elementu, niezmienniki indukcyjne ([13.04](13.04-formalna-weryfikacja-fifo-i-interfejsow-z.md)).

## Kod w module

- `hdl/` — `cnt10` i `fifo_sync` z samosprawdzającymi się testbenchami w trzech językach (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)). Właściwości formalne FIFO — w [hdl/sv/fifo_sync.sv](hdl/sv/fifo_sync.sv) pod `` `ifdef FORMAL ``.
- [formal/](formal/) — opakowania formalne ([cnt10_formal.sv](formal/cnt10_formal.sv), [cnt10_formal.vhd](formal/cnt10_formal.vhd) z PSL, [alu_hs_formal.sv](formal/alu_hs_formal.sv)), pliki SymbiYosys `.sby` z zadaniami BMC, dowodu, cover i wariantami z błędami, skrypty równoważności Yosysa `.ys`, [sprawdz.py](formal/sprawdz.py) porównujący wszystkie wyniki z oczekiwanymi (także oczekiwane FAIL i UNKNOWN) i [Makefile](formal/Makefile).
- CI: zadanie *Weryfikacja formalna* w [checks.yml](../../.github/workflows/checks.yml) — OSS CAD Suite, tabela wyników w podsumowaniu przebiegu, ślady VCD jako artefakt.
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 13.01 Dowód zamiast symulacji: BMC, indukcja i cover
- [ ] 13.02 SymbiYosys: pierwsze dowody
- [ ] 13.03 Pisanie właściwości: assume, assert, cover
- [ ] 13.04 Formalna weryfikacja FIFO i interfejsów z handshakiem
- [ ] 13.05 Sprawdzanie równoważności i metody formalne w przemyśle
