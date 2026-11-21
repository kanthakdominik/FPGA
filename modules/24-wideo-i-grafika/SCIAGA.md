# Ściąga — 24 — Wideo i grafika

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [24.01 — Sygnał wideo: taktowanie, wygaszanie i zegar piksela](24.01-sygnal-wideo-taktowanie-wygaszanie-i-zegar.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Linia: aktywne + przedsionek + synchronizacja + tylny próg; ramka analogicznie w liniach | każdy format wideo |
| Zegar piksela = H_TOT × V_TOT × odświeżanie | wybór PLL |
| 640×480 @ 60: 800 × 525, 25,175 MHz, HS/VS ujemne | DMT (VGA) |
| 720p60: 1650 × 750, 74,25 MHz; 1080p60: 2200 × 1125, 148,5 MHz; HS/VS dodatnie | CTA-861 |
| Wyjścia generatora rejestrowane razem; każdy stopień obrazu opóźnia synchronizację o tyle samo | potok wideo |
| W wygaszaniu kolor czarny; monitor cyfrowy synchronizuje się do DE | DVI/HDMI/panele |

## [24.02 — HDMI i DVI: kodowanie TMDS i nadajnik ADV7513 na DECA](24.02-hdmi-i-dvi-kodowanie-tmds-i-nadajnik-adv7513-na.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| TMDS: 8 → 10 bitów, 10× zegar piksela na parę; 3 pary danych + zegar | DVI/HDMI |
| q_m[8] — XOR/XNOR (minimalizacja zmian), q[9] — inwersja (równoważenie, licznik cnt) | koder TMDS |
| Dane: ≤ 5 zmian w symbolu, znaki sterujące: 7–8 zmian; HS/VS = C0/C1 na kanale niebieskim | synchronizacja słów |
| HDMI = DVI + wyspy danych (dźwięk, InfoFrame, TERC4) + preambuły i pasma ochronne | zgodność |
| ADV7513: I2C 0x72, po włączeniu 0x41 = 0x10 i rejestry stałe; po zaniku HPD konfiguracja od nowa | DECA |
| Zegar do nadajnika odwrócony (DDR 0/1) — próbkowanie w połowie bitu | interfejs równoległy |

## [24.03 — Grafika generowana: sprite'y, tekst i linie](24.03-grafika-generowana-sprite-y-tekst-i-linie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każda warstwa i synchronizacja opóźnione do opóźnienia najwolniejszej warstwy | mikser warstw |
| Tekst: komórka (x ≫ n, y ≫ n), adres wiersz·KOL + kolumna, bit czcionki z ROM — 2 takty | nakładka OSD |
| Sprite: dx = x − sx mod 2ᴺ, jedno porównanie dx < W; ruch tylko raz na ramkę | obiekty ruchome |
| Bresenham: e = dx + dy, e2 = 2e, krok x gdy e2 ≥ dy, krok y gdy e2 ≤ dx; 1 punkt/takt | odcinki |
| Punktów odcinka: max(|Δx|, |Δy|) + 1, błąd ≤ ½ piksela | weryfikacja |
| Rysowanie do pamięci w wygaszaniu albo do drugiego bufora — bez rozdarć | bitmapy |

## [24.04 — Bufor ramki w DDR3](24.04-bufor-ramki-w-ddr3.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przepustowość odczytu = piksele aktywne × B/piksel × odświeżanie (1080p60 × 4 B ≈ 500 MB/s); zapis drugie tyle | planowanie pamięci |
| Odczyt z wyprzedzeniem, burstami, do FIFO albo buforów linii w domenie piksela | każdy bufor ramki |
| Zdarzenia między domenami (linia, ramka) — bit przełączany + synchronizator; dane — pamięć dwuzegarowa | CDC |
| Zamiana ramek tylko w wygaszaniu pionowym; autor czeka na wykonanie zamiany | podwójne buforowanie |
| Rozdarcie = zapis do ramki wyświetlanej; potrójne buforowanie przy różnych tempach autora i ekranu | wybór schematu |
| Licznik/flaga niedoboru — pierwszy wskaźnik problemów z przepustowością | debug |

## [24.05 — Kamera MIPI CSI-2 na DECA](24.05-kamera-mipi-csi-2-na-deca.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| D-PHY: pas zegara + 1–4 pasy danych; HS różnicowy ok. 200 mV, LP 1,2 V do 10 Mb/s | warstwa fizyczna |
| Start HS: LP-11 → LP-01 → LP-00 → HS-0 → bajt synchronizacji 0xB8 | wyrównanie |
| Pakiet krótki: DI + 16 bitów + ECC; długi: DI + WC + ECC, dane, CRC-16 | CSI-2 |
| RAW10: 4 piksele w 5 bajtach; RAW8 0x2A, RAW10 0x2B, YUV422 0x1E, RGB888 0x24 | formaty |
| MAX 10: D-PHY przez sieć rezystorów (LVDS + wejścia 1,2 V), ok. 500–800 Mb/s na pas | DECA, AN 754 |
| Najpierw wzorzec testowy czujnika, potem rzeczywisty obraz | uruchamianie |

## [24.06 — Przetwarzanie obrazu strumieniowo: bufory linii i filtry 3×3](24.06-przetwarzanie-obrazu-strumieniowo-bufory-linii.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Okno N×N: N − 1 buforów linii + N² rejestrów; wynik 1 piksel/takt | przetwarzanie strumieniowe |
| Linia opóźniająca: zapis pod a, odczyt spod a + 1, adres krążący → opóźnienie dokładnie L | bufor linii w RAM |
| L = H_TOT: brzegi uzupełniane zerami i synchronizacja w tych samych liniach — bez porównań współrzędnych | prosty filtr |
| Opóźnienie ≈ jedna linia; synchronizację opóźnić dokładnie o tyle co piksele | wyrównanie |
| Sobel: \|Gx\| + \|Gy\|; współczynniki 1, 2, 4 — przesunięcia zamiast mnożeń | krawędzie, rozmycie |
| Szerokości: suma 3×3 z wagami ≤ 16 → 8 + 4 bity | zakresy |
