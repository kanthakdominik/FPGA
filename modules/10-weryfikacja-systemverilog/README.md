# 10 — Weryfikacja w SystemVerilogu

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 24 h · **Status:** ✅ pełny

## Po co ten moduł

Weryfikacyjna część SystemVeriloga: programowanie obiektowe, losowanie z ograniczeniami, pokrycie funkcjonalne i asercje SVA. To podstawa pracy inżyniera weryfikacji i przygotowanie do UVM.

## Wymagane wcześniej

[06 — SystemVerilog do projektowania](../06-systemverilog-rtl/README.md), [09 — Symulacja i testbenche](../09-symulacja-i-testbench/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 10.01 | [Programowanie obiektowe: klasy, dziedziczenie, polimorfizm](10.01-programowanie-obiektowe-klasy-dziedziczenie.md) | SystemVerilog | — | ✅ |
| 10.02 | [Losowanie z ograniczeniami (constrained random)](10.02-losowanie-z-ograniczeniami-constrained-random.md) | SystemVerilog | — | ✅ |
| 10.03 | [Pokrycie funkcjonalne: covergroup, coverpoint, cross](10.03-pokrycie-funkcjonalne-covergroup-coverpoint.md) | SystemVerilog | — | ✅ |
| 10.04 | [Asercje SVA: sekwencje i właściwości](10.04-asercje-sva-sekwencje-i-wlasciwosci.md) | SystemVerilog | — | ✅ |
| 10.05 | [Testbench warstwowy: driver, monitor, scoreboard](10.05-testbench-warstwowy-driver-monitor-scoreboard.md) | SystemVerilog | — | ✅ |
| 10.06 | [Komunikacja i współbieżność: mailbox, semafory, zdarzenia, fork-join](10.06-komunikacja-i-wspolbieznosc-mailbox-semafory.md) | SystemVerilog | — | ✅ |
| 10.07 | [Plan weryfikacji i pokrycie kodu](10.07-plan-weryfikacji-i-pokrycie-kodu.md) | — | — | ✅ |

## Po tym module potrafisz

- pisać klasy z dziedziczeniem i polimorfizmem,
- generować pobudzenia losowe z ograniczeniami,
- mierzyć pokrycie funkcjonalne i pokrycie kodu,
- pisać sekwencje i właściwości SVA,
- zbudować warstwowy testbench z driverem, monitorem i scoreboardem.

## Układ weryfikowany w module

Wszystkie testbenche modułu sprawdzają jeden układ: **`alu_hs`** — ALU z handshake valid/ready po obu stronach i rejestrem wyjściowym (wynik w następnym takcie, trzymany do odebrania).

| Kod `op` | Operacja | `carry` |
|----------|----------|---------|
| 0 ADD | `res = a + b` | przeniesienie |
| 1 SUB | `res = a − b` | pożyczka (a < b) |
| 2 AND, 3 OR, 4 XOR | logiczne | 0 |
| 5 SHL, 6 SHR | przesunięcie `a` o `b[2:0]` (logiczne) | 0 |
| 7 | kod niedozwolony: `err = 1`, `res = 0` | 0 |

`zero = 1`, gdy `res = 0`. Parametr `BUG` wstrzykuje błąd do sprawdzenia, czy testbench go wykrywa: `1` — pożyczka SUB liczona jako `a <= b` (błąd tylko dla a = b), `2` — `in_ready = 1` zawsze (nadpisanie nieodebranego wyniku). Opis kodu i wyniki: [10.05](10.05-testbench-warstwowy-driver-monitor-scoreboard.md).

## Kod w module

- `hdl/` — układ `alu_hs` i jego prosty, samosprawdzający się testbench w trzech językach (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `tb/` — testbenche weryfikacyjne w SystemVerilogu: transakcje i model ([alu_txn_pkg.sv](tb/alu_txn_pkg.sv)), pokrycie ([alu_cov_pkg.sv](tb/alu_cov_pkg.sv)), asercje ([alu_sva.sv](tb/alu_sva.sv)), interfejs ([alu_if.sv](tb/alu_if.sv)), środowisko warstwowe ([alu_env_pkg.sv](tb/alu_env_pkg.sv)) i sześć testów `tb_*.sv`.
- [sim/Makefile](sim/Makefile) — `make TB=…`, `make regresja`, `make ziarna`, `make pokrycie`. Wymaga Verilatora ≥ 5.050 z rozwiązywaczem SMT (`z3`) — w CI z [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build), osobne zadanie *Weryfikacja SystemVerilog* z artefaktem raportu pokrycia ([10.07](10.07-plan-weryfikacji-i-pokrycie-kodu.md#uruchomienie)).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 10.01 Programowanie obiektowe: klasy, dziedziczenie, polimorfizm
- [ ] 10.02 Losowanie z ograniczeniami (constrained random)
- [ ] 10.03 Pokrycie funkcjonalne: covergroup, coverpoint, cross
- [ ] 10.04 Asercje SVA: sekwencje i właściwości
- [ ] 10.05 Testbench warstwowy: driver, monitor, scoreboard
- [ ] 10.06 Komunikacja i współbieżność: mailbox, semafory, zdarzenia, fork-join
- [ ] 10.07 Plan weryfikacji i pokrycie kodu
