# 13 — Weryfikacja formalna

> **Część III** · **Oznaczenia:** 🔍💼 · **Ścieżki:** weryfikacja · **Szacowany czas:** ok. 12 h · **Status:** 🔲 szkielet

## Po co ten moduł

Dowodzenie poprawności zamiast szukania błędów przypadkowymi testami. Moduł używa SymbiYosys i asercji SystemVeriloga, a przykłady obejmują FIFO i interfejsy z handshakiem.

## Wymagane wcześniej

[10 — Weryfikacja w SystemVerilogu](../10-weryfikacja-systemverilog/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 13.01 | [Dowód zamiast symulacji: BMC, indukcja i cover](13.01-dowod-zamiast-symulacji-bmc-indukcja-i-cover.md) | SystemVerilog | — | 🔲 |
| 13.02 | [SymbiYosys: pierwsze dowody](13.02-symbiyosys-pierwsze-dowody.md) | SystemVerilog | — | 🔲 |
| 13.03 | [Pisanie właściwości: assume, assert, cover](13.03-pisanie-wlasciwosci-assume-assert-cover.md) | SystemVerilog | — | 🔲 |
| 13.04 | [Formalna weryfikacja FIFO i interfejsów z handshakiem](13.04-formalna-weryfikacja-fifo-i-interfejsow-z.md) | SystemVerilog | — | 🔲 |
| 13.05 | [Sprawdzanie równoważności i metody formalne w przemyśle](13.05-sprawdzanie-rownowaznosci-i-metody-formalne-w.md) | — | — | 🔲 |

## Po tym module potrafisz

- wyjaśnić BMC, indukcję i sprawdzanie osiągalności (cover),
- pisać założenia, asercje i cele pokrycia,
- udowodnić poprawność FIFO i protokołu valid/ready,
- opisać sprawdzanie równoważności i miejsce metod formalnych w przemyśle.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 13.01 Dowód zamiast symulacji: BMC, indukcja i cover
- [ ] 13.02 SymbiYosys: pierwsze dowody
- [ ] 13.03 Pisanie właściwości: assume, assert, cover
- [ ] 13.04 Formalna weryfikacja FIFO i interfejsów z handshakiem
- [ ] 13.05 Sprawdzanie równoważności i metody formalne w przemyśle
