# 17 — Uruchamianie i debug na sprzęcie

> **Część IV** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 10 h · **Status:** 🔲 szkielet

## Po co ten moduł

Co zrobić, gdy projekt działa w symulacji, a na płytce nie. Moduł uczy wbudowanych analizatorów logicznych (Signal Tap, ILA), sond JTAG i pomiarów przyrządami zewnętrznymi.

## Wymagane wcześniej

[03 — Przepływ projektowy od RTL do bitstreamu](../03-przeplyw-projektowy/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 17.01 | [Strategia uruchamiania: od diody do analizatora logicznego](17.01-strategia-uruchamiania-od-diody-do-analizatora.md) | — | 🛠️ | 🔲 |
| 17.02 | [Wbudowany analizator logiczny: Signal Tap i ILA](17.02-wbudowany-analizator-logiczny-signal-tap-i-ila.md) | — | 🛠️ | 🔲 |
| 17.03 | [In-System Sources and Probes, VIO i JTAG-to-Avalon](17.03-in-system-sources-and-probes-vio-i-jtag-to.md) | — | 🛠️ | 🔲 |
| 17.04 | [Pomiary zewnętrzne: oscyloskop, analizator logiczny, integralność sygnałów](17.04-pomiary-zewnetrzne-oscyloskop-analizator.md) | — | 🛠️ | 🔲 |
| 17.05 | [Działa w symulacji, nie działa na płytce — typowe przyczyny](17.05-dziala-w-symulacji-nie-dziala-na-plytce-typowe.md) | — | — | 🔲 |

## Po tym module potrafisz

- zaplanować uruchamianie projektu od najprostszych testów,
- użyć Signal Tap na DECA i opisać odpowiednik w Vivado (ILA),
- sterować i podglądać sygnały przez In-System Sources and Probes,
- zmierzyć sygnały oscyloskopem i analizatorem logicznym,
- rozpoznać typowe przyczyny rozbieżności symulacji ze sprzętem.

## Kod w module

- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 17.01 Strategia uruchamiania: od diody do analizatora logicznego
- [ ] 17.02 Wbudowany analizator logiczny: Signal Tap i ILA
- [ ] 17.03 In-System Sources and Probes, VIO i JTAG-to-Avalon
- [ ] 17.04 Pomiary zewnętrzne: oscyloskop, analizator logiczny, integralność sygnałów
- [ ] 17.05 Działa w symulacji, nie działa na płytce — typowe przyczyny
