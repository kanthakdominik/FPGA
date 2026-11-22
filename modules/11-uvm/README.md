# 11 — UVM — Universal Verification Methodology

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 24 h

## Po co ten moduł

Standardowa metodologia weryfikacji (IEEE 1800.2) używana w firmach projektujących układy. Moduł prowadzi od struktury środowiska do kompletnego testbencha UVM dla bloku z interfejsem rejestrowym.

## Wymagane wcześniej

[10 — Weryfikacja w SystemVerilogu](../10-weryfikacja-systemverilog/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 11.01 | [Po co metodologia: struktura środowiska UVM](11.01-po-co-metodologia-struktura-srodowiska-uvm.md) | SystemVerilog | — |
| 11.02 | [Komponenty, fazy i fabryka](11.02-komponenty-fazy-i-fabryka.md) | SystemVerilog | — |
| 11.03 | [Transakcje, sekwencje i sekwencer](11.03-transakcje-sekwencje-i-sekwencer.md) | SystemVerilog | — |
| 11.04 | [Agent, driver i monitor](11.04-agent-driver-i-monitor.md) | VHDL · Verilog · SystemVerilog | — |
| 11.05 | [Scoreboard, porty analizy i pokrycie](11.05-scoreboard-porty-analizy-i-pokrycie.md) | SystemVerilog | — |
| 11.06 | [Konfiguracja: uvm_config_db, testy i środowiska](11.06-konfiguracja-uvm-config-db-testy-i-srodowiska.md) | SystemVerilog | — |
| 11.07 | [Model rejestrów (RAL)](11.07-model-rejestrow-ral.md) | SystemVerilog | — |
| 11.08 | [Kompletny przykład: testbench UVM dla bloku z AXI4-Lite](11.08-kompletny-przyklad-testbench-uvm-dla-bloku-z.md) | SystemVerilog | — |

## Po tym module potrafisz

- opisać strukturę środowiska UVM i fazy symulacji,
- pisać transakcje, sekwencje, drivery i monitory,
- konfigurować środowisko przez uvm_config_db i fabrykę,
- zbudować scoreboard i zbierać pokrycie,
- użyć modelu rejestrów (RAL).

## Układ weryfikowany w module

**`axil_regs`** — blok rejestrów z interfejsem AXI4-Lite (podrzędnym): ID, CTRL (kod operacji, zezwolenie przerwania), argumenty OPA i OPB, RESULT (wynik ALU z modułu 10 liczony na bieżąco), STATUS z flagą błędu kasowaną zapisem 1 (W1C), SCRATCH z obsługą WSTRB, adres spoza mapy z odpowiedzią SLVERR, wyjście `irq`. Parametr `BUG` wstrzykuje błąd: `1` — SCRATCH ignoruje WSTRB, `2` — każdy zapis STATUS kasuje flagę. Mapa rejestrów i opis: [11.04](11.04-agent-driver-i-monitor.md#układ-weryfikowany).

## Kod w module

- `hdl/` — układ `axil_regs` i jego prosty, samosprawdzający się testbench w trzech językach (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `tb/` — środowisko UVM: interfejs z asercjami ([axil_if.sv](tb/axil_if.sv)), agent AXI4-Lite ([axil_pkg.sv](tb/axil_pkg.sv)), model rejestrów ([regs_ral_pkg.sv](tb/regs_ral_pkg.sv)), środowisko ze scoreboardem i pokryciem ([env_pkg.sv](tb/env_pkg.sv)), 7 testów ([tests_pkg.sv](tb/tests_pkg.sv)), moduł górny ([tb_uvm.sv](tb/tb_uvm.sv)).
- [sim/Makefile](sim/Makefile) — `make TEST=…`, `make regresja`, `make bledy`. Wymaga Verilatora ≥ 5.050 z `z3` (np. [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build)) i biblioteki [uvm-core](https://github.com/accellera-official/uvm-core) 2020.3.1 (`UVM_HOME`). W CI — zadanie *Weryfikacja SystemVerilog i UVM* ([11.08](11.08-kompletny-przyklad-testbench-uvm-dla-bloku-z.md#uruchomienie)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
