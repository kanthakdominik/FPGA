# Ściąga — 14 — Statyczna analiza czasowa (STA)

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [14.01 — Ścieżki czasowe, setup, hold i zapas (slack)](14.01-sciezki-czasowe-setup-hold-i-zapas-slack.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| zapas setup = T + skew − t_su − (t_co + t_logika + t_poł)_max | każda ścieżka rejestr–rejestr |
| zapas hold = (t_co + t_logika + t_poł)_min − (skew + t_h) | każda ścieżka rejestr–rejestr |
| f_max = 1 / (t_co + t_logika + t_poł + t_su − skew) | najgorsza ścieżka domeny zegara |
| Hold nie zależy od okresu — niższa częstotliwość go nie naprawi | diagnoza naruszeń |
| Setup sprawdzany modelem wolnym (max), hold — szybkim (min) | narożniki |
| W FPGA połączenia to często 50–60 % opóźnienia ścieżki | szacowanie f_max |
| Cel: WNS ≥ 0 i WHS ≥ 0 we wszystkich modelach | zamknięcie czasu |

## [14.02 — Zegar w praktyce: skew, jitter i niepewność](14.02-zegar-w-praktyce-skew-jitter-i-niepewnosc.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| skew = latencja odbiornika − latencja nadajnika | każda ścieżka |
| Skew dodatni: setup +, hold −; ujemny: odwrotnie | analiza naruszeń |
| Niepewność odejmowana od zapasu setup i hold | `set_clock_uncertainty` |
| `derive_clock_uncertainty` — zawsze w SDC Quartusa | MAX 10, Cyclone, Arria |
| Projekt przechodzi we **wszystkich** narożnikach (MAX 10: Slow 85C, Slow 0C, Fast 0C) | zamknięcie czasu |
| CRPR oddaje pesymizm wspólnej części drzewa zegara | raporty z OCV |
| Zegar tylko z sieci globalnych/PLL; podział zegara — zezwoleniem albo `create_generated_clock` | kodowanie |

## [14.03 — Ograniczenia SDC: zegary, zegary generowane, opóźnienia wejść i wyjść](14.03-ograniczenia-sdc-zegary-zegary-generowane.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każdy zegar wejściowy: `create_clock`; każdy zegar wytworzony: `create_generated_clock` | zawsze |
| Wyjścia PLL: `derive_pll_clocks` albo jawne zegary generowane (czytelniejsze nazwy) | Quartus |
| Zegary niezależne: `set_clock_groups -asynchronous` | wiele oscylatorów |
| `set_input_delay -max` = t_co,max + t_płytka,max; `-min` = t_co,min + t_płytka,min | wejścia synchroniczne |
| `set_output_delay -max` = t_su + t_płytka,max; `-min` = t_płytka,min − t_h | wyjścia synchroniczne |
| Drugie ograniczenie na tym samym porcie wymaga `-add_delay` | DDR, wiele zegarów |
| `check_timing` / `report_ucp` po każdej zmianie SDC | kompletność |

## [14.04 — Wyjątki: false path, multicycle, max/min delay](14.04-wyjatki-false-path-multicycle-max-min-delay.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `-setup N` + `-hold N−1` | ścieżka wielotaktowa w jednej domenie |
| Samo `-setup N` przesuwa hold na (N−1)·T — prawie zawsze błąd | multicycle |
| `-end`: okresy zegara odbierającego; `-start`: nadającego | zegary o różnych okresach |
| Szybki → wolny: `-start`; wolny → szybki: `-end` | multicycle między zegarami |
| Priorytet: false path > max/min delay > multicycle | wiele wyjątków |
| Każdy wyjątek ma uzasadnienie w kodzie (enable, synchronizator) i test | przegląd SDC |
| Między domenami asynchronicznymi: `set_clock_groups`, nie false path ścieżka po ścieżce | CDC |

## [14.05 — Czytanie raportów: Timing Analyzer i Vivado](14.05-czytanie-raportow-timing-analyzer-i-vivado.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Kolejność: ostrzeżenia SDC → zegary → kompletność → podsumowanie → przejścia → ścieżki → wyjątki | każdy raport |
| Wynik liczy się ze **wszystkich** modeli (Multicorner Summary) | zamknięcie czasu |
| Dziwna relacja zboczy = problem z zegarami, nie z logiką | diagnoza |
| Połączenia > 70 % ścieżki przy małej liczbie poziomów = wachlarz / rozmieszczenie | diagnoza |
| Dużo poziomów logiki = architektura (potok) | diagnoza |
| Raport po syntezie to szacunek; wiążący — po place & route | wczesna analiza |
| WNS/TNS/WHS w CI jako liczby, porównywane z poprzednią kompilacją | regresja zapasu |

## [14.06 — Ograniczenia interfejsów źródłowo-synchronicznych](14.06-ograniczenia-interfejsow-zrodlowo.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Zegar przesyłany definiowany na **pinie** wyjściowym (`create_generated_clock`), opóźnienia danych względem niego | wyjścia źródłowo-synchroniczne |
| Zegar przesyłany: rejestr DDR w bloku I/O (dane 1/0), nie logika | powyżej kilkudziesięciu MHz |
| Wejście: setup/hold-based `-max = UI − t_su`, `-min = t_h`; skew-based `±skew` | wejścia źródłowo-synchroniczne |
| DDR: drugie ograniczenie z `-clock_fall -add_delay` + false path dla nieużywanych par zboczy | interfejsy DDR |
| Zegar z rejestru do SPI: MOSI `-setup -start DIV`, `-hold -start 2·DIV−1`; MISO `-setup -end DIV`, `-hold -end 2·DIV−1` | SPI tryb 0 z tego modułu |
| Odczyt SPI: pół okresu SCLK ≥ t_zegar→pin + 2·t_płytka + t_co + t_wejście + t_su | f_SCLK max |
| DDR 125 MHz, ±0,5 ns rozrzutu → okno 3 ns | budżet interfejsu |
