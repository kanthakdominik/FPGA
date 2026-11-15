# 10 — Weryfikacja w SystemVerilogu

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 24 h · **Status:** 🔲 szkielet

## Po co ten moduł

Weryfikacyjna część SystemVeriloga: programowanie obiektowe, losowanie z ograniczeniami, pokrycie funkcjonalne i asercje SVA. To podstawa pracy inżyniera weryfikacji i przygotowanie do UVM.

## Wymagane wcześniej

[06 — SystemVerilog do projektowania](../06-systemverilog-rtl/README.md), [09 — Symulacja i testbenche](../09-symulacja-i-testbench/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 10.01 | [Programowanie obiektowe: klasy, dziedziczenie, polimorfizm](10.01-programowanie-obiektowe-klasy-dziedziczenie.md) | SystemVerilog | — | 🔲 |
| 10.02 | [Losowanie z ograniczeniami (constrained random)](10.02-losowanie-z-ograniczeniami-constrained-random.md) | SystemVerilog | — | 🔲 |
| 10.03 | [Pokrycie funkcjonalne: covergroup, coverpoint, cross](10.03-pokrycie-funkcjonalne-covergroup-coverpoint.md) | SystemVerilog | — | 🔲 |
| 10.04 | [Asercje SVA: sekwencje i właściwości](10.04-asercje-sva-sekwencje-i-wlasciwosci.md) | SystemVerilog | — | 🔲 |
| 10.05 | [Testbench warstwowy: driver, monitor, scoreboard](10.05-testbench-warstwowy-driver-monitor-scoreboard.md) | SystemVerilog | — | 🔲 |
| 10.06 | [Komunikacja i współbieżność: mailbox, semafory, zdarzenia, fork-join](10.06-komunikacja-i-wspolbieznosc-mailbox-semafory.md) | SystemVerilog | — | 🔲 |
| 10.07 | [Plan weryfikacji i pokrycie kodu](10.07-plan-weryfikacji-i-pokrycie-kodu.md) | — | — | 🔲 |

## Po tym module potrafisz

- pisać klasy z dziedziczeniem i polimorfizmem,
- generować pobudzenia losowe z ograniczeniami,
- mierzyć pokrycie funkcjonalne i pokrycie kodu,
- pisać sekwencje i właściwości SVA,
- zbudować warstwowy testbench z driverem, monitorem i scoreboardem.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

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
