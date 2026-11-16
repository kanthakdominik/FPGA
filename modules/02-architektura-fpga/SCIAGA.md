# Ściąga — 02 — Architektura układów FPGA

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [02.01 — Od PAL i CPLD do FPGA — ewolucja układów programowalnych](02.01-od-pal-i-cpld-do-fpga-ewolucja-ukladow.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| CPLD: suma iloczynów, stałe opóźnienia, mało logiki, nieulotny | układy klasyczne (MAX 7000, XC9500, GAL) |
| FPGA: LUT + przerzutnik, opóźnienia zależne od rozmieszczenia, dużo logiki | wszystkie współczesne rodziny |
| Pierwsze FPGA: Xilinx XC2064, 1985 | historia, rozmowy |
| MAX 10 = FPGA (LUT4) z wbudowaną pamięcią flash, konfiguracja poniżej 10 ms | płytka DECA |
| Antifuse — programowany raz, odporny na promieniowanie | lotnictwo, kosmos |

## [02.02 — LUT, przerzutnik i blok logiczny: LE, ALM, CLB, slice](02.02-lut-przerzutnik-i-blok-logiczny-le-alm-clb-slice.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10: LE = LUT4 + 1 rejestr; LAB = 16 LE | szacowanie zasobów |
| LAB MAX 10: 2 zegary, 2 zezwolenia, 2 asynchroniczne kasowania, 1 synchroniczne kasowanie, 1 synchroniczne ładowanie | pakowanie rejestrów |
| AMD seria 7: slice = 4 LUT6 + 8 rejestrów; CLB = 2 slice'y | porównywanie rodzin |
| Mniej zestawów sterujących = lepsze upakowanie i rozmieszczenie | styl kodu |
| Liczba LE/komórek logicznych różnych producentów nie jest porównywalna wprost | wybór układu |

## [02.03 — Łańcuchy przeniesień i logika arytmetyczna](02.03-lancuchy-przeniesien-i-logika-arytmetyczna.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10: 1 bit sumatora/licznika = 1 LE; łańcuch 16 bitów na LAB, dalej w tej samej kolumnie | szacowanie zasobów i rozmieszczenia |
| Tryb arytmetyczny: LUT4 → dwie LUT3 (suma i przeniesienie) | MAX 10, Cyclone IV |
| Opóźnienie łańcucha rośnie liniowo z liczbą bitów | szerokie sumatory i liczniki |
| `+`, `-`, `<`, `>` i liczniki trafiają na łańcuch przeniesień | styl kodu |
| Za wolny łańcuch → potokowanie, carry-select, liczniki segmentowane | zamykanie timingu |

## [02.04 — Sieć połączeń i dlaczego trasowanie kosztuje czas](02.04-siec-polaczen-i-dlaczego-trasowanie-kosztuje.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Połączenia to zwykle połowa lub więcej opóźnienia ścieżki krytycznej | układy FPGA |
| Opóźnienia połączeń są znane dopiero po rozmieszczeniu i trasowaniu | czytanie raportów |
| Rejestruj wejścia i wyjścia modułów, pamięci i DSP | projekty powyżej kilkudziesięciu MHz |
| Wykorzystanie powyżej ok. 80% utrudnia zamknięcie timingu | wybór układu |
| Sygnały o dużym rozgałęzieniu: sieć globalna albo powielenie rejestru | resety, zezwolenia, sygnały wyboru |

## [02.05 — Bloki pamięci i pamięć rozproszona](02.05-bloki-pamieci-i-pamiec-rozproszona.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| M9K: 9216 bitów, do ×36 (true dual-port do ×18) | MAX 10 |
| 10M50: 182 bloki M9K, 1638 Kb | płytka DECA |
| Bloki pamięci mają odczyt synchroniczny — odczyt asynchroniczny nie trafi do bloku | wnioskowanie pamięci z HDL |
| MAX 10 nie ma pamięci rozproszonej (LUTRAM/MLAB) | małe pamięci w MAX 10 |
| Rejestr wyjściowy pamięci: +1 takt, krótsza ścieżka | projekty z wyższym zegarem |
| Osobne zegary portów = gotowe przejście między domenami (FIFO asynchroniczne) | CDC |

## [02.06 — Bloki DSP i mnożarki sprzętowe](02.06-bloki-dsp-i-mnozarki-sprzetowe.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10: blok = 18 × 18 albo 2 × (9 × 9); 10M50 — 144 bloki | szacowanie zasobów |
| MAX 10: sumatory i akumulatory przy mnożarkach są w LE | filtry, MAC |
| AMD DSP48E1: 25 × 18, akumulator 48 bitów, sumator wstępny | porównania, przenoszenie projektów |
| Rejestruj wejścia i wyjście mnożarki — rejestry wejdą do bloku | wysoka częstotliwość |
| Mnożenie $N \times M$ powyżej szerokości bloku = kilka bloków + sumatory | szerokie mnożenia |
| Wymuszenie realizacji: `multstyle` (Quartus), `use_dsp` (Vivado) | brak bloków, stałe |

## [02.07 — Zegary: sieci globalne, PLL i MMCM](02.07-zegary-sieci-globalne-pll-i-mmcm.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| $f_{out} = f_{in} \cdot M / (N \cdot C)$; VCO $= f_{in} \cdot M / N$ w zakresie z karty katalogowej | PLL |
| MAX 10 (10M50, F484): do 20 GCLK, 4 PLL, po 5 wyjść C0–C4 | płytka DECA |
| Zegar z pinu zegarowego, nie z dowolnego pinu | projekt płytki, przypisanie pinów |
| Wyjścia PLL są ważne dopiero po `locked = 1` | reset układu |
| Nie robi się zegarów z logiki — zezwolenie albo PLL | zawsze |
| AMD seria 7: CMT = MMCM + PLL; 32 BUFG | porównania |

## [02.08 — Bloki wejścia-wyjścia i banki I/O](02.08-bloki-wejscia-wyjscia-i-banki-i-o.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Wszystkie piny banku mają wspólne VCCIO — standard musi pasować | przypisywanie pinów |
| DECA: banki 1A/1B/2 — 2,5 V, 3/4 — 3,3 V, 5/6 — 1,5 V, 7 — 1,8 V, 8 — 1,2 V | płytka DECA |
| Rejestr przy pinie (IOE) = przewidywalne czasy na pinach | interfejsy synchroniczne |
| MAX 10: LVDS do 720 Mb/s; prawdziwe nadajniki LVDS tylko w bankach dolnych | szybkie interfejsy |
| Pamięci DDR tylko w bankach po prawej stronie (10M16+) | projekt płytki z MAX 10 |
| SSTL/HSTL wymagają VREF w banku | interfejsy pamięci |

## [02.09 — Konfiguracja: SRAM, flash, antifuse — MAX 10 jako FPGA z wbudowaną pamięcią flash](02.09-konfiguracja-sram-flash-antifuse-max-10-jako.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `.sof` → CRAM przez JTAG (ulotne), `.pof` → wewnętrzny flash (trwałe) | MAX 10, Quartus |
| MAX 10 konfiguruje się z wewnętrznej flash w czasie poniżej 10 ms | start systemu |
| CFM — obrazy konfiguracji, UFM — dane użytkownika, CRAM — konfiguracja w pracy | MAX 10 |
| Tryb konfiguracji decyduje o liczbie obrazów i rozmiarze UFM | MAX 10 |
| FPGA SRAM potrzebuje zewnętrznej pamięci konfiguracji | AMD, większość Altera, Lattice ECP5 |
| Antifuse: jednorazowe, odporne na promieniowanie; flash (PolarFire): odporne, wielokrotne | zastosowania specjalne |

## [02.10 — Przegląd rynku: AMD, Altera, Lattice, Microchip, Gowin, Efinix](02.10-przeglad-rynku-amd-altera-lattice-microchip.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| AMD (Xilinx) i Altera — pełna gama; Lattice — małe i energooszczędne; Microchip — flash i odporność na promieniowanie | orientacja na rynku |
| MAX 10 obsługuje bezpłatny Quartus Prime Lite | nauka na DECA |
| Pełny otwarty przepływ: iCE40, ECP5, część Gowin, GateMate | projekty open source |
| Zapas zasobów przy wyborze układu: 30–50% | nowy projekt |
| Kod RTL bez prymitywów producenta przenosi się między rodzinami; PLL, pamięci IP, nadajniki — nie | architektura projektu |
