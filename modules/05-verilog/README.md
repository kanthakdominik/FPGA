# 05 — Verilog

> **Część II** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, weryfikacja, DECA · **Szacowany czas:** ok. 18 h

## Po co ten moduł

Verilog (IEEE 1364) — najprostszy z trzech języków i wciąż najczęściej spotykany w kodzie, który dostaniesz w spadku. Moduł kładzie nacisk na reguły przypisań blokujących i nieblokujących oraz na pułapki z rozmiarem i znakiem liczb.

## Wymagane wcześniej

[01 — Logika cyfrowa dla projektanta FPGA](../01-logika-cyfrowa/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 05.01 | [Moduły, porty, wire i reg](05.01-moduly-porty-wire-i-reg.md) | VHDL · Verilog · SystemVerilog | — |
| 05.02 | [Operatory, liczby, rozmiar i znak](05.02-operatory-liczby-rozmiar-i-znak.md) | VHDL · Verilog · SystemVerilog | — |
| 05.03 | [assign i always: logika kombinacyjna i sekwencyjna](05.03-assign-i-always-logika-kombinacyjna-i.md) | VHDL · Verilog · SystemVerilog | — |
| 05.04 | [Przypisania blokujące i nieblokujące — reguły Cummingsa](05.04-przypisania-blokujace-i-nieblokujace-reguly.md) | VHDL · Verilog · SystemVerilog | — |
| 05.05 | [Parametry, localparam, generate i instancjonowanie](05.05-parametry-localparam-generate-i-instancjonowanie.md) | VHDL · Verilog · SystemVerilog | 🛠️ `pwm` |
| 05.06 | [Funkcje, zadania i dyrektywy kompilatora](05.06-funkcje-zadania-i-dyrektywy-kompilatora.md) | VHDL · Verilog · SystemVerilog | — |
| 05.07 | [Pułapki Verilogu: niejawne sieci, obcinanie, znak i wyścigi](05.07-pulapki-verilogu-niejawne-sieci-obcinanie-znak.md) | VHDL · Verilog · SystemVerilog | — |

## Po tym module potrafisz

- napisać moduł w Verilogu z parametrami i instancjonować go,
- stosować reguły przypisań blokujących i nieblokujących i wyjaśnić, skąd się biorą,
- kontrolować rozmiar i znak wyrażeń arytmetycznych,
- unikać niejawnych sieci, obcinania i warunków wyścigu w symulacji.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- [deca/pwm](deca/pwm/) — projekt dla płytki Arrow DECA: moduł nadrzędny w trzech językach, `pwm.sdc`, `utworz_projekt.tcl` i `Makefile` ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
