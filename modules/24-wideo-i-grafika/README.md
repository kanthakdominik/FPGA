# 24 — Wideo i grafika

> **Część V** · **Oznaczenia:** 🛠️ · **Ścieżki:** DECA · **Szacowany czas:** ok. 18 h

## Po co ten moduł

Generowanie obrazu z FPGA: taktowanie sygnału wideo, wyjście HDMI przez nadajnik ADV7513 na DECA, grafika generowana, bufor ramki w DDR3 i kamera MIPI. Wideo to jeden z najbardziej satysfakcjonujących obszarów do nauki.

## Wymagane wcześniej

[18 — Pamięci w FPGA](../18-pamieci/README.md), [15 — Zegary, reset i przejścia między domenami (CDC)](../15-zegary-reset-cdc/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 24.01 | [Sygnał wideo: taktowanie, wygaszanie i zegar piksela](24.01-sygnal-wideo-taktowanie-wygaszanie-i-zegar.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 24.02 | [HDMI i DVI: kodowanie TMDS i nadajnik ADV7513 na DECA](24.02-hdmi-i-dvi-kodowanie-tmds-i-nadajnik-adv7513-na.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 24.03 | [Grafika generowana: sprite'y, tekst i linie](24.03-grafika-generowana-sprite-y-tekst-i-linie.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 24.04 | [Bufor ramki w DDR3](24.04-bufor-ramki-w-ddr3.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 24.05 | [Kamera MIPI CSI-2 na DECA](24.05-kamera-mipi-csi-2-na-deca.md) | — | 🛠️ |
| 24.06 | [Przetwarzanie obrazu strumieniowo: bufory linii i filtry 3×3](24.06-przetwarzanie-obrazu-strumieniowo-bufory-linii.md) | VHDL · Verilog · SystemVerilog | 🛠️ |

## Po tym module potrafisz

- wygenerować taktowanie wideo dla dowolnej rozdzielczości,
- skonfigurować nadajnik HDMI i wyświetlić obraz z DECA,
- rysować grafikę i tekst w czasie rzeczywistym,
- zbudować bufor ramki w pamięci zewnętrznej,
- przetwarzać obraz strumieniowo filtrami 3×3.

## Układy w module

- **`takt_wideo`** — generator taktowania: liczniki, HS/VS z polaryzacją, DE, współrzędne x/y, tryb przez parametry ([24.01](24.01-sygnal-wideo-taktowanie-wygaszanie-i-zegar.md)).
- **`tmds_kod`** — koder TMDS według DVI 1.0: minimalizacja zmian, równoważenie składowej stałej, znaki sterujące ([24.02](24.02-hdmi-i-dvi-kodowanie-tmds-i-nadajnik-adv7513-na.md)).
- **`adv7513_konfig`** — konfiguracja nadajnika HDMI ADV7513 przez I2C: tablica rejestrów, seria po resecie, na żądanie i cyklicznie, wykrywanie NACK ([24.02](24.02-hdmi-i-dvi-kodowanie-tmds-i-nadajnik-adv7513-na.md)).
- **`znaki`, `sprite16`, `linia_bres`** — nakładka tekstowa z czcionką 5×7, sprite 16×16 z przezroczystością, odcinki algorytmem Bresenhama ([24.03](24.03-grafika-generowana-sprite-y-tekst-i-linie.md)).
- **`czytnik_linii`, `bufor_ramki`** — odczyt linii obrazu burstami Avalon-MM do buforów linii w pamięci dwuzegarowej, podwójne buforowanie ramek, wykrywanie niedoboru ([24.04](24.04-bufor-ramki-w-ddr3.md)).
- **`filtr3x3`** — okno 3×3 na dwóch liniach opóźniających: rozmycie, Sobel, krawędzie progowane ([24.06](24.06-przetwarzanie-obrazu-strumieniowo-bufory-linii.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)): `tb_takt` (trzy tryby), `tb_tmds` (dekoder i własności kodu), `tb_adv` (model odbiornika I2C z pomiarem czasów), `tb_grafika` (odcinki, tekst, sprite), `tb_bufor` (model pamięci z burstami, dwa zegary, klasyfikacja ramek), `tb_filtr` (model splotu).
- [narzedzia/](narzedzia/) — `czcionka.py` i `sprite.py`: generują funkcje ROM czcionki i obrazka sprite'a (VHDL, Verilog, testbenche) z rysunków ASCII.
- [deca/hdmi/](deca/hdmi/) — 640×480 przez ADV7513: tło, tekst, sprite i odcinki ([24.01](24.01-sygnal-wideo-taktowanie-wygaszanie-i-zegar.md)–[24.03](24.03-grafika-generowana-sprite-y-tekst-i-linie.md)); [deca/obraz/](deca/obraz/) — bufor dwóch ramek w pamięci na chipie z czytnikiem Avalon-MM, generatorem animacji i filtrem 3×3 ([24.04](24.04-bufor-ramki-w-ddr3.md), [24.06](24.06-przetwarzanie-obrazu-strumieniowo-bufory-linii.md)); `deca_top` w trzech językach, `.sdc`, `utworz_projekt.tcl` z przypisaniami z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)). Kamera MIPI ([24.05](24.05-kamera-mipi-csi-2-na-deca.md)) — ścieżka uruchomienia w tekście, bez projektu (wymaga modułu kamery).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).
