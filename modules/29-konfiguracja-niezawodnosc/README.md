# 29 — Konfiguracja, bezpieczeństwo i niezawodność

> **Część VI** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 12 h · **Status:** 🔲 szkielet

## Po co ten moduł

Co dzieje się z projektem po wdrożeniu: tryby konfiguracji, zdalna aktualizacja z dwoma obrazami w MAX 10, ochrona bitstreamu, odporność na promieniowanie i normy bezpieczeństwa funkcjonalnego.

## Wymagane wcześniej

[03 — Przepływ projektowy od RTL do bitstreamu](../03-przeplyw-projektowy/README.md), [18 — Pamięci w FPGA](../18-pamieci/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 29.01 | [Tryby konfiguracji i pamięci konfiguracyjne](29.01-tryby-konfiguracji-i-pamieci-konfiguracyjne.md) | — | — | 🔲 |
| 29.02 | [Podwójny obraz i zdalna aktualizacja w MAX 10](29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 29.03 | [Szyfrowanie i ochrona bitstreamu](29.03-szyfrowanie-i-ochrona-bitstreamu.md) | — | — | 🔲 |
| 29.04 | [Promieniowanie i SEU: TMR, scrubbing i ECC](29.04-promieniowanie-i-seu-tmr-scrubbing-i-ecc.md) | VHDL · Verilog · SystemVerilog | — | 🔲 |
| 29.05 | [Bezpieczeństwo funkcjonalne: DO-254, IEC 61508, ISO 26262](29.05-bezpieczenstwo-funkcjonalne-do-254-iec-61508.md) | — | — | 🔲 |

## Po tym module potrafisz

- dobrać tryb konfiguracji i pamięć konfiguracyjną,
- zrealizować zdalną aktualizację z podwójnym obrazem w MAX 10,
- opisać szyfrowanie i ochronę bitstreamu,
- zastosować TMR, ECC i scrubbing przeciw błędom SEU,
- opisać wymagania DO-254, IEC 61508 i ISO 26262 wobec projektu FPGA.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 29.01 Tryby konfiguracji i pamięci konfiguracyjne
- [ ] 29.02 Podwójny obraz i zdalna aktualizacja w MAX 10
- [ ] 29.03 Szyfrowanie i ochrona bitstreamu
- [ ] 29.04 Promieniowanie i SEU: TMR, scrubbing i ECC
- [ ] 29.05 Bezpieczeństwo funkcjonalne: DO-254, IEC 61508, ISO 26262
