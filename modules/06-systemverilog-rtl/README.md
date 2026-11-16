# 06 — SystemVerilog do projektowania

> **Część II** · **Oznaczenia:** 🧩💼 · **Ścieżki:** RTL, weryfikacja · **Szacowany czas:** ok. 16 h · **Status:** ✅ pełny

## Po co ten moduł

Syntezowalna część SystemVeriloga (IEEE 1800): konstrukcje, które zastępują Verilog w nowych projektach i chronią przed błędami — always_ff, always_comb, typy wyliczeniowe, struktury, pakiety i interfejsy. Moduł pokazuje też, co z tego faktycznie obsługują Quartus Lite, Vivado i Yosys.

## Wymagane wcześniej

[05 — Verilog](../05-verilog/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 06.01 | [logic, always_comb, always_ff i always_latch](06.01-logic-always-comb-always-ff-i-always-latch.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 06.02 | [Typy użytkownika: enum, struct, union, typedef i tablice spakowane](06.02-typy-uzytkownika-enum-struct-union-typedef-i.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 06.03 | [Pakiety i parametryzacja typami](06.03-pakiety-i-parametryzacja-typami.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 06.04 | [Interfejsy i modporty](06.04-interfejsy-i-modporty.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 06.05 | [unique, priority i bezpieczne instrukcje case](06.05-unique-priority-i-bezpieczne-instrukcje-case.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 06.06 | [Asercje natychmiastowe w kodzie RTL](06.06-asercje-natychmiastowe-w-kodzie-rtl.md) | VHDL · Verilog · SystemVerilog | — | ✅ |
| 06.07 | [Co z SystemVeriloga obsługują narzędzia syntezy](06.07-co-z-systemveriloga-obsluguja-narzedzia-syntezy.md) | — | — | ✅ |

## Po tym module potrafisz

- pisać RTL z logic, always_ff, always_comb i typami użytkownika,
- organizować kod w pakiety i parametryzować go typami,
- łączyć bloki interfejsami z modportami,
- sprawdzić, które konstrukcje przejdą przez syntezę w danym narzędziu.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 06.01 logic, always_comb, always_ff i always_latch
- [ ] 06.02 Typy użytkownika: enum, struct, union, typedef i tablice spakowane
- [ ] 06.03 Pakiety i parametryzacja typami
- [ ] 06.04 Interfejsy i modporty
- [ ] 06.05 unique, priority i bezpieczne instrukcje case
- [ ] 06.06 Asercje natychmiastowe w kodzie RTL
- [ ] 06.07 Co z SystemVeriloga obsługują narzędzia syntezy
