# Ściąga — 31 — Projekty końcowe na DECA

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [31.01 — Projekt 1: zegar i stoper sterowany komendami przez UART](31.01-projekt-1-zegar-i-stoper-sterowany-komendami.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Liczniki BCD: gotowe znaki `0x30 + cyfra`, bez dzielenia; przeniesienie przy 9 (jednostki) i 5 (dziesiątki min/s) | zegary, wyświetlacze |
| Takt setnych: 50 MHz / 500 000; sekunda: 100 setnych | ten projekt |
| Po `start` nadajnika `gotowy` spada takt później — jeden takt przerwy przed następnym bajtem | `uart_tx` z 20.01 |
| Testbench jak terminal: bajty szeregowo, porównanie całych linii | interfejsy tekstowe |
| Czas w testbenchu przyspieszony parametrami (sekunda = 10 000 taktów), logika ta sama | długie przedziały czasu |
| Tolerancja ±1 jednostki przy porównaniu z czasem testbencha — faza dzielnika | pomiary czasu |

## [31.02 — Projekt 2: oscyloskop na wbudowanym ADC z obrazem przez HDMI](31.02-projekt-2-oscyloskop-na-wbudowanym-adc-z.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Wyzwolenie zboczem: `poprzednia < poziom <= bieżąca` — porównanie z poprzednią próbką, nie samo `>=` | oscyloskopy, detektory zdarzeń |
| Pre-trigger: pamięć kołowa, początek = adres wyzwolenia − PRZED | rejestratory, logic analyzer (17.x) |
| Blok danych między domenami: dane stabilne + przełącznik gotowy/potwierdzenie, nie synchronizator na każdym bicie | CDC bloków |
| Przełączanie bufora tylko w wygaszaniu pionowym — brak rozerwanego obrazu | grafika, bufory ramki |
| Pamięć z opóźnieniem 1 takt — adres z wyprzedzeniem o 1 piksel | każdy odczyt w torze wideo |
| 640×480 @ 60 Hz: zegar 25,175 MHz (25 MHz działa na większości monitorów), 800 × 525 taktów na ramkę | VGA/HDMI |
| MAX 10 ADC: 12 bitów, do 1 MSPS, odniesienie wewnętrzne 2,5 V | DECA |

## [31.03 — Projekt 3: syntezator dźwięku sterowany przez UART lub MIDI](31.03-projekt-3-syntezator-dzwieku-sterowany-przez.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MIDI: 31 250 b/s, 8N1, bajt statusu ma bit 7 = 1 | każdy interfejs MIDI |
| Running status — dane bez statusu; `F8`–`FF` w środku komunikatu nie przerywają; `F0`–`F7` kasują status | dekodery MIDI |
| Note On z prędkością 0 = Note Off | klawiatury |
| f = krok · fs / 2^N; rozdzielczość fs / 2^N (tu 2,9 mHz) | DDS, NCO |
| Półton: × 2^(1/12) ≈ 1,0595; oktawa: × 2 (przesunięcie) | tablice nut |
| A4 = nuta 69 = 440 Hz | strojenie |
| Współdzielenie w czasie: takty na próbkę / takty na głos = maksymalna liczba głosów | audio, DSP |

## [31.04 — Projekt 4: system z Nios V, DDR3 i strumieniem UDP](31.04-projekt-4-system-z-nios-v-ddr3-i-strumieniem-udp.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Avalon-MM: żądanie przyjęte przy `read && !waitrequest`; dane z `readdatavalid`, w kolejności | mastery Avalon |
| Limit „w locie + w buforze ≤ pojemność bufora” — bufor nigdy się nie przepełni | każdy master z potokiem odczytu |
| Całą ramkę buforuj przed nadawaniem, jeśli źródło może się wstrzymać — MII nie ma pauzy | Ethernet, wideo, audio |
| Ethernet: ramka 64–1518 B z FCS, dane UDP ≤ 1472 B (MTU 1500 − 20 IP − 8 UDP) | UDP/IPv4 |
| 100 Mb/s: na ramkę + 8 B preambuły + 12 B przerwy; 1472 B danych → maks. ok. 95,7 Mb/s danych | przepustowość |
| Rejestr statusu W1C — skasowanie flagi bez wyścigu odczyt–modyfikacja–zapis | peryferia z flagami |
| Procesor z pamięcią podręczną danych: zapis bufora → flush przed START | Nios V/g, ARM, DMA |

## [31.05 — Projekt 5: przetwarzanie obrazu z kamery MIPI w czasie rzeczywistym](31.05-projekt-5-przetwarzanie-obrazu-z-kamery-mipi-w.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Bayer RGGB: 50 % G, 25 % R, 25 % B; każdy piksel ma jedną składową | czujniki kolorowe |
| Okno k × k strumieniowo: k − 1 buforów linii, opóźnienie ok. (k−1)/2 linii | filtry lokalne |
| Y = (77R + 150G + 29B + 128) >> 8 — BT.601 w stałym przecinku | luminancja |
| Zmiany parametrów potoku tylko w wygaszaniu pionowym | wideo w czasie rzeczywistym |
| Wszystkie ścieżki wyboru muszą mieć to samo opóźnienie (albo wyrównanie) | multipleksery w torze wideo |
| Weryfikuj na obszarach, gdzie wynik jest znany analitycznie; brzegi osobno | testbenche obrazowe |
| 640 × 480 @ 60 Hz: 25 Mpx/s → przy 1 pikselu na takt zegar ≥ 25 MHz | wideo |

## [31.06 — Projekt 6: własny procesor RISC-V z peryferiami](31.06-projekt-6-wlasny-procesor-risc-v-z-peryferiami.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Peryferia mapowane w pamięci: dekodowanie po najstarszych bitach, odczyt z tym samym opóźnieniem co RAM | SoC |
| Flaga W1C: zapis 1 kasuje — brak wyścigu z ustawieniem sprzętowym | rejestry statusu |
| Następne porównanie = poprzednie + okres — błąd nie kumuluje się | timery, harmonogramy |
| Porównanie ze znakiem różnicy (`mtimecmp`) zamiast równości — odporne na spóźnienie | timery RISC-V |
| Status „wolny” musi uwzględniać zapis w drodze (`start` i takt po nim) | rejestry z opóźnionym skutkiem |
| Program w repozytorium jako źródło + generator; pliki `.hex` / `.mif` sprawdzane w CI | firmware w FPGA |
| RAM 1024 × 32 = 32 kbit = 4 M9K na MAX 10 | szacowanie zasobów |
