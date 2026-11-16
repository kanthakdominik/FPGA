# 14 — Statyczna analiza czasowa (STA)

> **Część IV** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

Jak narzędzie sprawdza, czy projekt zadziała z zadaną częstotliwością, i jak mu to poprawnie opisać. Ograniczenia SDC są wspólne dla Quartusa, Vivado (XDC) i wielu innych narzędzi.

## Wymagane wcześniej

[03 — Przepływ projektowy od RTL do bitstreamu](../03-przeplyw-projektowy/README.md), [07 — Kodowanie pod syntezę — wzorce RTL](../07-kodowanie-pod-synteze/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 14.01 | [Ścieżki czasowe, setup, hold i zapas (slack)](14.01-sciezki-czasowe-setup-hold-i-zapas-slack.md) | — | — | 🔲 |
| 14.02 | [Zegar w praktyce: skew, jitter i niepewność](14.02-zegar-w-praktyce-skew-jitter-i-niepewnosc.md) | — | — | 🔲 |
| 14.03 | [Ograniczenia SDC: zegary, zegary generowane, opóźnienia wejść i wyjść](14.03-ograniczenia-sdc-zegary-zegary-generowane.md) | — | 🛠️ | 🔲 |
| 14.04 | [Wyjątki: false path, multicycle, max/min delay](14.04-wyjatki-false-path-multicycle-max-min-delay.md) | — | 🛠️ | 🔲 |
| 14.05 | [Czytanie raportów: Timing Analyzer i Vivado](14.05-czytanie-raportow-timing-analyzer-i-vivado.md) | — | 🛠️ | 🔲 |
| 14.06 | [Ograniczenia interfejsów źródłowo-synchronicznych](14.06-ograniczenia-interfejsow-zrodlowo.md) | — | 🛠️ | 🔲 |

## Po tym module potrafisz

- policzyć zapas setup i hold dla ścieżki rejestr–rejestr,
- uwzględnić skew, jitter i niepewność zegara,
- napisać ograniczenia SDC dla zegarów, wejść i wyjść,
- poprawnie stosować false path, multicycle i max/min delay,
- czytać raporty Timing Analyzera i Vivado.

## Kod w module

- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 14.01 Ścieżki czasowe, setup, hold i zapas (slack)
- [ ] 14.02 Zegar w praktyce: skew, jitter i niepewność
- [ ] 14.03 Ograniczenia SDC: zegary, zegary generowane, opóźnienia wejść i wyjść
- [ ] 14.04 Wyjątki: false path, multicycle, max/min delay
- [ ] 14.05 Czytanie raportów: Timing Analyzer i Vivado
- [ ] 14.06 Ograniczenia interfejsów źródłowo-synchronicznych
