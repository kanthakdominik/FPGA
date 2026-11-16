# 24 — Wideo i grafika

> **Część V** · **Oznaczenia:** 🛠️ · **Ścieżki:** DECA · **Szacowany czas:** ok. 18 h · **Status:** 🔲 szkielet

## Po co ten moduł

Generowanie obrazu z FPGA: taktowanie sygnału wideo, wyjście HDMI przez nadajnik ADV7513 na DECA, grafika generowana, bufor ramki w DDR3 i kamera MIPI. Wideo to jeden z najbardziej satysfakcjonujących obszarów do nauki.

## Wymagane wcześniej

[18 — Pamięci w FPGA](../18-pamieci/README.md), [15 — Zegary, reset i przejścia między domenami (CDC)](../15-zegary-reset-cdc/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 24.01 | [Sygnał wideo: taktowanie, wygaszanie i zegar piksela](24.01-sygnal-wideo-taktowanie-wygaszanie-i-zegar.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 24.02 | [HDMI i DVI: kodowanie TMDS i nadajnik ADV7513 na DECA](24.02-hdmi-i-dvi-kodowanie-tmds-i-nadajnik-adv7513-na.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 24.03 | [Grafika generowana: sprite'y, tekst i linie](24.03-grafika-generowana-sprite-y-tekst-i-linie.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 24.04 | [Bufor ramki w DDR3](24.04-bufor-ramki-w-ddr3.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 24.05 | [Kamera MIPI CSI-2 na DECA](24.05-kamera-mipi-csi-2-na-deca.md) | — | 🛠️ | 🔲 |
| 24.06 | [Przetwarzanie obrazu strumieniowo: bufory linii i filtry 3×3](24.06-przetwarzanie-obrazu-strumieniowo-bufory-linii.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |

## Po tym module potrafisz

- wygenerować taktowanie wideo dla dowolnej rozdzielczości,
- skonfigurować nadajnik HDMI i wyświetlić obraz z DECA,
- rysować grafikę i tekst w czasie rzeczywistym,
- zbudować bufor ramki w pamięci zewnętrznej,
- przetwarzać obraz strumieniowo filtrami 3×3.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty dla płytki Arrow DECA: moduł nadrzędny w trzech językach, ograniczenia czasowe (`.sdc`) i skrypt `utworz_projekt.tcl`, który tworzy projekt Quartusa z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 24.01 Sygnał wideo: taktowanie, wygaszanie i zegar piksela
- [ ] 24.02 HDMI i DVI: kodowanie TMDS i nadajnik ADV7513 na DECA
- [ ] 24.03 Grafika generowana: sprite'y, tekst i linie
- [ ] 24.04 Bufor ramki w DDR3
- [ ] 24.05 Kamera MIPI CSI-2 na DECA
- [ ] 24.06 Przetwarzanie obrazu strumieniowo: bufory linii i filtry 3×3
