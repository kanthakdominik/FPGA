# 15 — Zegary, reset i przejścia między domenami (CDC)

> **Część IV** · **Oznaczenia:** 🧩🛠️💼 · **Ścieżki:** RTL, weryfikacja, DECA · **Szacowany czas:** ok. 18 h · **Status:** 🔲 szkielet

## Po co ten moduł

Najczęstsze źródło błędów, które przechodzą symulację i pojawiają się dopiero na sprzęcie. Moduł omawia generowanie zegarów, metastabilność, synchronizatory, asynchroniczne FIFO i strategie resetu.

## Wymagane wcześniej

[14 — Statyczna analiza czasowa (STA)](../14-analiza-czasowa/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 15.01 | [Generowanie zegarów: PLL, clock enable i dlaczego nie bramkować zegara](15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 15.02 | [Metastabilność i MTBF — rachunek](15.02-metastabilnosc-i-mtbf-rachunek.md) | — | — | 🔲 |
| 15.03 | [Synchronizatory jednobitowe i synchronizacja impulsów](15.03-synchronizatory-jednobitowe-i-synchronizacja.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 15.04 | [Przesyłanie słów: handshake, kod Graya i MCP](15.04-przesylanie-slow-handshake-kod-graya-i-mcp.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 15.05 | [Asynchroniczna kolejka FIFO](15.05-asynchroniczna-kolejka-fifo.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 15.06 | [Strategie resetu: synchronizator resetu i RDC](15.06-strategie-resetu-synchronizator-resetu-i-rdc.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 15.07 | [Ograniczenia i weryfikacja CDC](15.07-ograniczenia-i-weryfikacja-cdc.md) | — | 🛠️ | 🔲 |

## Po tym module potrafisz

- wygenerować zegary PLL-em i wyjaśnić, dlaczego nie bramkuje się zegara logiką,
- policzyć MTBF synchronizatora,
- przesłać pojedynczy bit, impuls i słowo wielobitowe między domenami,
- zaprojektować asynchroniczne FIFO z licznikami w kodzie Graya,
- zaprojektować synchronizator resetu i opisać przejścia w ograniczeniach.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 15.01 Generowanie zegarów: PLL, clock enable i dlaczego nie bramkować zegara
- [ ] 15.02 Metastabilność i MTBF — rachunek
- [ ] 15.03 Synchronizatory jednobitowe i synchronizacja impulsów
- [ ] 15.04 Przesyłanie słów: handshake, kod Graya i MCP
- [ ] 15.05 Asynchroniczna kolejka FIFO
- [ ] 15.06 Strategie resetu: synchronizator resetu i RDC
- [ ] 15.07 Ograniczenia i weryfikacja CDC
