# Płytka Arrow DECA i układ MAX 10

[← README](../README.md)

> **Status:** 🔲 szkielet — dane zebrane z instrukcji płytki, tabele pinów do uzupełnienia razem z tematem [00.06](../modules/00-srodowisko-pracy/00.06-pierwszy-projekt-migajaca-dioda-w-trzech.md).

DECA to płytka ewaluacyjna firmy Arrow (zaprojektowana przez Terasic, 2015) z układem Altera MAX 10. Jest bogato wyposażona jak na swoją cenę: pamięć DDR3, HDMI, Ethernet, kodek audio, złącze kamery MIPI, czujniki i wbudowany programator. Dlatego nadaje się zarówno do pierwszych ćwiczeń, jak i do projektów końcowych z [modułu 31](../modules/31-projekty-koncowe/README.md).

## Układ FPGA

| Parametr | Wartość |
|----------|---------|
| Układ | MAX 10 **10M50DAF484C6G** — 10M50: ok. 50 tys. elementów logicznych, D: zasilanie dwunapięciowe, A: wersja z blokami analogowymi (ADC), F484: obudowa BGA 484, C6: zakres komercyjny, klasa szybkości 6 |
| Pamięć blokowa | 1638 Kb w blokach M9K |
| Pętle PLL | 4 |
| Pamięć flash w układzie | konfiguracja (CFM) z możliwością dwóch obrazów oraz pamięć użytkownika (UFM) — podział zależy od trybu konfiguracji ([moduł 18](../modules/18-pamieci/README.md), [moduł 29](../modules/29-konfiguracja-niezawodnosc/README.md)) |
| Przetworniki ADC | 2 × 12 bitów, wbudowany czujnik temperatury ([moduł 20](../modules/20-interfejsy-szeregowe/README.md)) |

⚠️ **Sprawdź napis na układzie.** Wczesne egzemplarze DECA mają układ w wersji inżynierskiej z dopiskiem **ES** (`10M50DAF484C6GES`). W Quartusie trzeba wtedy wybrać dokładnie ten układ — plik dla wersji produkcyjnej może się nie wgrać.

## Co jest na płytce

| Grupa | Elementy | Moduły |
|-------|----------|--------|
| Programowanie | Wbudowany USB-Blaster II (JTAG) | 00, 03, 17 |
| Pamięci | 512 MB DDR3 (magistrala 16 bitów), 64 MB QSPI flash, gniazdo microSD | 23 |
| Wejścia i wyjścia proste | 8 niebieskich diod, 2 przyciski, 2 przełączniki suwakowe, 2 przyciski pojemnościowe (CapSense) | 00, 07, 08 |
| Zegary | generatory 50 MHz, m.in. `MAX10_CLK1_50` i `MAX10_CLK2_50` | 00, 15 |
| Wideo | Nadajnik HDMI (HDMI 1.4), złącze kamery MIPI | 24 |
| Dźwięk | Kodek audio 24-bitowy, wejście i wyjście liniowe | 25 |
| Sieć i USB | Ethernet 10/100, USB 2.0 OTG | 25 |
| Czujniki | akcelerometr, czujnik temperatury, czujnik wilgotności i temperatury, czujnik zbliżeniowy i światła | 20 |
| Analogowe | 2 wejścia SMA do przetworników ADC układu MAX 10 | 20, 31 |
| Rozszerzenia | 2 złącza 46-stykowe zgodne z BeagleBone | 20, 31 |
| Zasilanie | Zewnętrzny zasilacz 5 V, min. 3 A; przetwornice Enpirion na płytce | — |

## Piny

Wspólne przypisania pinów dla wszystkich projektów będą w pliku `deca_piny.tcl` w tym katalogu, dołączanym przez skrypty `utworz_projekt.tcl` ([zasady](../docs/STYL-KODU.md#projekty-na-deca)). Każdy pin trzeba przepisać z tabel w *DECA User Manual* razem ze standardem I/O.

| Sygnał | Pin | Standard I/O | Opis |
|--------|-----|--------------|------|
| `MAX10_CLK1_50` | PIN_M8 | 2.5 V | zegar 50 MHz |
| `MAX10_CLK2_50` | PIN_P11 | 3.3 V | zegar 50 MHz |
| diody, przyciski, przełączniki | — | — | _do uzupełnienia (DECA User Manual, rozdz. 3)_ |

## Planowane strony

- Przegląd płytki ze zdjęciem i schematem blokowym.
- Quartus i programowanie: tworzenie projektu skryptem, wgrywanie `.sof` przez JTAG i `.pof` do wewnętrznej pamięci flash.
- Pełna mapa pinów (`deca_piny.tcl`) z opisem banków I/O i ich napięć.
- Cechy specyficzne dla MAX 10: konfiguracja z wewnętrznej pamięci flash („instant-on”), podwójny obraz, UFM, ADC, wewnętrzny oscylator.
- Peryferia: układy na płytce (nadajnik HDMI, PHY Ethernet, kodek, czujniki), ich interfejsy i noty katalogowe.

## Źródła

- *DECA User Manual*, Terasic/Arrow, 2015 — opis płytki i tabele pinów.
- [MAX 10 FPGA Device Overview](https://www.intel.com/content/www/us/en/docs/programmable/683658/) i [MAX 10 FPGA Configuration User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683865/).
