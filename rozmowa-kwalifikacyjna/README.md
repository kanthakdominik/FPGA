# Rozmowa kwalifikacyjna na stanowisko FPGA

[← README](../README.md)

> **Status:** 🔲 szkielet — sekcje wypełniają się razem z modułami.

Ten katalog zbiera z całej bazy to, o co pytają na rozmowach technicznych na stanowiska: **FPGA Design Engineer**, **RTL Design Engineer**, **Design Verification Engineer** i **FPGA Engineer** w firmach z branży telekomunikacyjnej, motoryzacyjnej, lotniczej, obronnej, medycznej, pomiarowej i finansowej (handel wysokich częstotliwości).

## Zawartość

| Plik | Co zawiera |
|------|------------|
| [pytania.md](pytania.md) | Pytania ze wszystkich modułów z wzorcowymi odpowiedziami, ułożone według modułów |
| [zadania-projektowe.md](zadania-projektowe.md) | Zadania „napisz na tablicy”: od detektora zbocza do asynchronicznego FIFO — z rozwiązaniem w trzech językach |
| [pulapki.md](pulapki.md) | Pytania podchwytliwe i częste błędne odpowiedzi |

## Jak wygląda rekrutacja (do rozwinięcia)

1. **Rozmowa wstępna** — doświadczenie, projekty, motywacja.
2. **Test techniczny** — pytania zamknięte albo zadanie domowe (moduł w HDL z testbenchem).
3. **Rozmowa techniczna** — logika cyfrowa, timing i CDC, kodowanie na tablicy, omówienie własnego projektu.
4. **Rozmowa końcowa** — zespół, sposób pracy, oczekiwania.

## Tematy, które wracają najczęściej

Oznaczone 💼 w [mapie modułów](../README.md#mapa-modułów). Najważniejsze:

- przypisania blokujące i nieblokujące, zatrzaski, lista wrażliwości — [moduły 04–07](../modules/07-kodowanie-pod-synteze/README.md),
- automaty stanów — [moduł 08](../modules/08-automaty-stanow/README.md),
- setup, hold, zapas i maksymalna częstotliwość — [moduł 14](../modules/14-analiza-czasowa/README.md),
- metastabilność, synchronizatory, asynchroniczne FIFO — [moduł 15](../modules/15-zegary-reset-cdc/README.md),
- potokowanie i kompromis powierzchnia–szybkość — [moduł 16](../modules/16-wydajnosc-zasoby-moc/README.md),
- UART, SPI, I²C — [moduł 20](../modules/20-interfejsy-szeregowe/README.md),
- AXI — [moduł 21](../modules/21-magistrale-on-chip/README.md),
- SystemVerilog weryfikacyjny i UVM — [moduły 10–11](../modules/10-weryfikacja-systemverilog/README.md),
- własny projekt z portfolio — [moduł 31](../modules/31-projekty-koncowe/README.md).
