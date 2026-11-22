# Płytka Arrow DECA i układ MAX 10

[← README](../README.md)

> — opis płytki, pełna mapa pinów i plik pinów dla Quartusa są gotowe; opisy peryferiów powstają razem z modułami, które z nich korzystają.

DECA to płytka ewaluacyjna firmy Arrow z układem Altera MAX 10, zaprojektowana i udokumentowana przez Terasic (2015). Jak na swoją cenę jest bardzo bogato wyposażona: pamięć DDR3, HDMI, Ethernet, kodek audio, złącze kamery MIPI, czujniki i wbudowany programator. Dzięki temu wystarcza na całą bazę — od pierwszej diody w [module 00](../modules/00-srodowisko-pracy/README.md) do projektów końcowych w [module 31](../modules/31-projekty-koncowe/README.md).

| Strona | Zawartość |
|--------|-----------|
| [piny.md](piny.md) | Pełna mapa pinów: banki I/O, wszystkie sygnały, standardy dla Quartusa, uwagi o stanach aktywnych |
| [deca_piny.tcl](deca_piny.tcl) | Te same przypisania jako skrypt Tcl: `deca_ustawienia_ukladu`, `deca_pin`, `deca_grupa` |
| [deca_projekt.tcl](deca_projekt.tcl) | Wspólna procedura `deca_utworz_projekt` używana przez skrypty projektów w modułach |
| [deca.mk](deca.mk) | Wspólne reguły `make` dla projektów: tworzenie projektu, kompilacja, wgrywanie do SRAM i flash |
| [sprawdz_czasy.tcl](sprawdz_czasy.tcl) | Zapas setup i hold we wszystkich modelach pracy; kod błędu przy ujemnym zapasie (`make czas`) |
| [zrodla.md](zrodla.md) | Instrukcja, schemat, BOM, projekty społeczności, otwarty kontroler DDR3 |

## Układ FPGA

| Parametr | Wartość |
|----------|---------|
| Układ | MAX 10 **10M50DAF484C6G** — 10M50: ok. 50 tys. elementów logicznych, D: zasilanie dwunapięciowe, A: wersja z blokami analogowymi (ADC), F484: obudowa BGA 484, C6: zakres komercyjny, klasa szybkości 6 |
| Elementy logiczne | ok. 50 000 LE |
| Pamięć blokowa | 1638 Kb (bloki M9K) |
| Pamięć flash użytkownika | do 5888 Kb — podział między konfigurację a UFM zależy od trybu konfiguracji |
| Pętle PLL | 4 |
| Przetworniki ADC | 2, każdy z jednym wejściem dedykowanym i ośmioma dwufunkcyjnymi; czujnik temperatury w układzie |

⚠️ **Sprawdź napis na układzie.** Wiele płytek ma układ w wersji inżynierskiej **`10M50DAF484C6GES`** — tak ustawiają projekty T. Verbeure'a i DECAfpga, i tak domyślnie ustawia [deca_piny.tcl](deca_piny.tcl). Jeśli na układzie nie ma dopisku ES, podaj `10M50DAF484C6G` przy tworzeniu projektu.

## Co jest na płytce

| Grupa | Elementy | Moduły |
|-------|----------|--------|
| Programowanie | Wbudowany USB-Blaster II (złącze mini-USB), tryb JTAG | 00, 03, 17 |
| Pamięci | 512 MB DDR3 (magistrala 16 bitów), 64 MB QSPI flash, gniazdo microSD | 18, 23 |
| Proste wejścia i wyjścia | 8 niebieskich diod, 2 przyciski, 2 przełączniki suwakowe, 2 przyciski pojemnościowe (CY8CMBR3102, I²C) | 00, 07, 08 |
| Zegary | Trzy generatory 50 MHz dla logiki użytkownika (`MAX10_CLK1_50`, `MAX10_CLK2_50`, `DDR3_CLK_50`) i 10 MHz dla ADC (`ADC_CLK_10`) | 00, 15 |
| Wideo | Nadajnik HDMI ADV7513 (HDMI 1.4), złącze kamery MIPI CSI-2 | 24 |
| Dźwięk | Kodek TLV320AIC3254, 24 bity, wejście i wyjście liniowe | 25 |
| Sieć i USB | Ethernet 10/100 (PHY DP83620, RJ45), USB 2.0 OTG (PHY ULPI, mini-USB AB) | 25 |
| Czujniki | Akcelerometr LIS2DH12, czujnik temperatury LM71, wilgotności i temperatury HDC1000, zbliżeniowy i światła Si1143, monitor zasilania INA230 | 20 |
| Analogowe | 2 wejścia SMA do ADC układu MAX 10 | 20, 31 |
| Rozszerzenia | 2 złącza 46-stykowe zgodne z BeagleBone (P8 i P9): 69 cyfrowych I/O i 7 wejść analogowych | 20, 31 |
| Zasilanie | Zasilacz 5 V, 3 A (w zestawie); przetwornice Altera Enpirion | — |

## Najważniejsze fakty na start

- **Diody LED świecą przy stanie niskim.** Logika daje 1 → dioda zgaszona. W module nadrzędnym trzeba odwrócić sygnał.
- **Przyciski `KEY[1:0]` dają 0 po wciśnięciu.** Mają sprzętowy przerzutnik Schmitta, ale sygnał z przycisku i tak trzeba zsynchronizować z zegarem ([00.06](../modules/00-srodowisko-pracy/00.06-pierwszy-projekt-migajaca-dioda-w-trzech.md)).
- **Banki I/O mają różne napięcia** (1,2 V do 3,3 V) — standard I/O każdego pinu musi do nich pasować. Tabela banków jest w [piny.md](piny.md#banki-io-i-napięcia).
- **Zegar podstawowy:** `MAX10_CLK1_50`, pin M8, 50 MHz, standard 2,5 V.
- **MAX 10 konfiguruje się sam z wewnętrznej pamięci flash** po wgraniu pliku `.pof`. Plik `.sof` wgrywa konfigurację tylko do pamięci SRAM — znika po wyłączeniu zasilania.

## Planowane strony

- Cechy MAX 10: tryby konfiguracji, podwójny obraz, UFM, ADC, wewnętrzny oscylator — moduły 02, 18, 20 i 29.
- Peryferia: nadajnik HDMI, PHY Ethernet, kodek, czujniki — w modułach 20, 24 i 25.

## Źródła

- *DECA User Manual*, Terasic, 2017 — rozdz. 2 (zawartość płytki), rozdz. 3 (konfiguracja, zegary, tabele pinów 3-2 do 3-21). Odnośniki w [zrodla.md](zrodla.md).
- *DECA Schematic* — banki I/O i napięcia.
- [MAX 10 FPGA Device Overview](https://www.intel.com/content/www/us/en/docs/programmable/683658/) i [MAX 10 FPGA Configuration User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683865/).
