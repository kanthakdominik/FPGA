# Ściąga — 20 — Interfejsy szeregowe niskiej szybkości

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [20.01 — UART: nadajnik, odbiornik i nadpróbkowanie](20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Spoczynek = 1, start = 0, dane od LSB, stop = 1; 8N1 = 10 bitów na bajt | ramka UART |
| 115 200 b/s → 8,68 µs na bit, 11 520 B/s; przy 50 MHz 434 takty na bit | typowa szybkość |
| Suma odchyłek zegarów obu stron < ok. 4 % (8N1); praktycznie ±2 % na stronę | tolerancja łącza |
| Odbiornik: synchronizator, 16 próbek na bit, większość z 3 w środku bitu | nadpróbkowanie |
| Akumulator fazy: `acc += BAUD`, impuls i `acc −= CLK_HZ` przy przepełnieniu | dokładna szybkość z dowolnego zegara |
| RS-232 to ±3…15 V z odwróconą logiką — nie do pinu FPGA | poziomy elektryczne |
| Wracaj do czekania na start w środku bitu stopu | zapas dla szybszego nadajnika |

## [20.02 — SPI: master i slave, tryby CPOL/CPHA](20.02-spi-master-i-slave-tryby-cpol-cpha.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| CPOL — poziom SCLK w spoczynku; CPHA = 0 — próbkowanie na zboczu wiodącym, 1 — na końcowym | definicja trybu |
| Tryby 0 i 3: próbkowanie na narastającym, zmiana na opadającym | najczęstsze układy |
| SPI jest zawsze pełnodupleksowe: N taktów wymienia N bitów w obie strony | odczyt = wysłanie czegokolwiek |
| CS niski przez całą transakcję wielobajtową | rejestry z autoinkrementacją |
| Master z SCLK z logiki: wszystko w jednej domenie; MISO wraca w pół okresu SCLK | szybkość mastera |
| Slave z nadpróbkowaniem: f_clk ≥ ok. 8–10·f_SCLK | slave w FPGA |
| LIS2DH12: tryb 3, do 10 MHz; LM71: tryb 0, 3-przewodowy | DECA |

## [20.03 — I²C: master, open-drain i rozciąganie zegara](20.03-i2c-master-open-drain-i-rozciaganie-zegara.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Open-drain: na pin tylko 0 albo Z; linia = AND wszystkich wyjść | elektryka I²C |
| SDA zmienia się tylko przy SCL = 0; zmiana przy SCL = 1 to START (↓) albo STOP (↑) | protokół |
| Sm 100 kHz: t_LOW ≥ 4,7 µs, t_HIGH ≥ 4,0 µs, t_r ≤ 1 µs; Fm 400 kHz: 1,3 / 0,6 µs, 300 ns | czasy |
| R_p(max) = t_r / (0,8473·C_b); R_p(min) = (V_DD − 0,4 V)/3 mA | dobór podciągania |
| Bajt + ACK = 9 taktów SCL; ACK = 0, NACK = 1; ostatni bajt odczytu z NACK | transakcja |
| Po zwolnieniu SCL czekaj, aż linia będzie wysoka, potem odmierzaj t_HIGH | rozciąganie zegara |
| Arbitraż: nadaję 1, czytam 0 → przegrałem, zwalniam linie | wielu masterów |

## [20.04 — PWM, enkodery kwadraturowe i serwomechanizmy](20.04-pwm-enkodery-kwadraturowe-i-serwomechanizmy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Centrowany PWM: f = f_clk/(2·OKRES); edge-aligned: f_clk/OKRES | dobór zegara |
| Nowe wypełnienie tylko w ustalonym punkcie okresu (rejestr cieniowy) | zmiany w trakcie pracy |
| Czas martwy po każdej zmianie: oba wyłączone; skraca każdy impuls o MARTWY | gałąź mostka |
| Gwarancję braku przewodzenia skrośnego daje sterownik bramek, nie tylko FPGA | bezpieczeństwo |
| Serwo: 50 Hz, 1–2 ms (1,5 ms środek) | modelarstwo |
| Enkoder: Gray 00→10→11→01, dekodowanie ×4 = 4·CPR kroków na obrót | pozycja |
| Zmiana A i B naraz = zgubiony krok, licz jako błąd | diagnostyka |
| Filtr wejść: stan stały przez FILTR taktów; max ok. f_clk/(FILTR + 3) kroków/s | drgania i zakłócenia |

## [20.05 — Czujniki na DECA: akcelerometr, temperatura i wilgotność](20.05-czujniki-na-deca-akcelerometr-temperatura-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Start sterownika: rozruch → identyfikator → konfiguracja → cykliczny odczyt | każdy czujnik |
| LIS2DH12: SPI tryb 3, WHO_AM_I 0x0F = 0x33, CTRL_REG1 0x20, CTRL_REG4 0x23, OUT_X_L 0x28 | akcelerometr DECA |
| LIS2DH12: bit 7 = odczyt, bit 6 = autoinkrementacja; BDU = spójne bajty L/H | odczyt wielobajtowy |
| LIS2DH12 HR ±2 g: 16 bitów wyrównane do lewej, 1 mg = 16 jednostek surowych | przeliczenie |
| LM71: 14 bitów U2 w bitach 15:2, 0,03125 °C/LSB | termometr DECA |
| HDC1000: adres 0x40, konfiguracja 0x02 = 0x1000, wyzwolenie wskaźnikiem 0x00, ~13 ms, NACK w trakcie | czujnik wilgotności |
| T = s·165/2¹⁶ − 40; RH = s·100/2¹⁶ | HDC1000 |

## [20.06 — Wbudowany przetwornik ADC w MAX 10](20.06-wbudowany-przetwornik-adc-w-max-10.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10 ADC: SAR, 12 bitów, do 1 MSPS na blok; 10M50 — dwa bloki | parametry |
| Zakres 0–2,5 V (układy dwuzasilaniowe, jak 10M50D na DECA); LSB ≈ 0,61 mV | wejście analogowe |
| Zegar ADC tylko z wyjścia PLL | wymóg sprzętowy |
| Termodioda: kanał 17, tylko ADC1; 25 °C ≈ kod 3677; kod maleje z temperaturą | temperatura układu |
| Rozkaz przyjęty, gdy valid ∧ ready (ready latency 0); odpowiedź bez przeciwciśnienia | *ADC Control Core Only* |
| Średnia z N próbek: szum / √N; 64 próbki ≈ +3 bity | uśrednianie szumu |
| Uśrednianie nie usuwa INL, błędu wzmocnienia i przesunięcia | kalibracja |
