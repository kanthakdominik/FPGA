# 11 — UVM — Universal Verification Methodology

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 24 h · **Status:** 🔲 szkielet

## Po co ten moduł

Standardowa metodologia weryfikacji (IEEE 1800.2) używana w firmach projektujących układy. Moduł prowadzi od struktury środowiska do kompletnego testbencha UVM dla bloku z interfejsem rejestrowym.

## Wymagane wcześniej

[10 — Weryfikacja w SystemVerilogu](../10-weryfikacja-systemverilog/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 11.01 | [Po co metodologia: struktura środowiska UVM](11.01-po-co-metodologia-struktura-srodowiska-uvm.md) | SystemVerilog | — | 🔲 |
| 11.02 | [Komponenty, fazy i fabryka](11.02-komponenty-fazy-i-fabryka.md) | SystemVerilog | — | 🔲 |
| 11.03 | [Transakcje, sekwencje i sekwencer](11.03-transakcje-sekwencje-i-sekwencer.md) | SystemVerilog | — | 🔲 |
| 11.04 | [Agent, driver i monitor](11.04-agent-driver-i-monitor.md) | SystemVerilog | — | 🔲 |
| 11.05 | [Scoreboard, porty analizy i pokrycie](11.05-scoreboard-porty-analizy-i-pokrycie.md) | SystemVerilog | — | 🔲 |
| 11.06 | [Konfiguracja: uvm_config_db, testy i środowiska](11.06-konfiguracja-uvm-config-db-testy-i-srodowiska.md) | SystemVerilog | — | 🔲 |
| 11.07 | [Model rejestrów (RAL)](11.07-model-rejestrow-ral.md) | SystemVerilog | — | 🔲 |
| 11.08 | [Kompletny przykład: testbench UVM dla bloku z AXI4-Lite](11.08-kompletny-przyklad-testbench-uvm-dla-bloku-z.md) | SystemVerilog | — | 🔲 |

## Po tym module potrafisz

- opisać strukturę środowiska UVM i fazy symulacji,
- pisać transakcje, sekwencje, drivery i monitory,
- konfigurować środowisko przez uvm_config_db i fabrykę,
- zbudować scoreboard i zbierać pokrycie,
- użyć modelu rejestrów (RAL).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 11.01 Po co metodologia: struktura środowiska UVM
- [ ] 11.02 Komponenty, fazy i fabryka
- [ ] 11.03 Transakcje, sekwencje i sekwencer
- [ ] 11.04 Agent, driver i monitor
- [ ] 11.05 Scoreboard, porty analizy i pokrycie
- [ ] 11.06 Konfiguracja: uvm_config_db, testy i środowiska
- [ ] 11.07 Model rejestrów (RAL)
- [ ] 11.08 Kompletny przykład: testbench UVM dla bloku z AXI4-Lite
