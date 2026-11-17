# Ściąga — 17 — Uruchamianie i debug na sprzęcie

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [17.01 — Strategia uruchamiania: od diody do analizatora logicznego](17.01-strategia-uruchamiania-od-diody-do-analizatora.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Jedna niewiadoma naraz: zasilanie → JTAG → konfiguracja → dioda → wejścia → PLL → bloki | uruchamianie |
| Bicie serca w każdej domenie zegarowej | każdy projekt |
| Liczniki zdarzeń i flagi lepkie zamiast pojedynczych impulsów | błędy przejściowe |
| Identyfikator/wersja projektu w rejestrze | pewność, co jest w układzie |
| Miernik: wynik = f · BRAMKA / f_ref ± 1; okno 1 ms przy 50 MHz → rozdzielczość 1 kHz | pomiar zegarów |
| Licznik przez domenę — tylko w kodzie Graya | miernik częstotliwości |
| `jtagconfig` przed szukaniem błędów w projekcie | brak programowania |

## [17.02 — Wbudowany analizator logiczny: Signal Tap i ILA](17.02-wbudowany-analizator-logiczny-signal-tap-i-ila.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Pamięć analizatora = głębokość × liczba sygnałów (256 × 16 = 4 Kb, pół M9K) | planowanie zasobów |
| Jeden analizator = jeden zegar próbkowania; sygnały z innej domeny — niepewność ±1 takt | wybór sygnałów |
| Bada się rejestry, nie wyjścia logiki kombinacyjnej | wybór sygnałów |
| Sygnały sprzed syntezy chronić atrybutem (`keep`, `preserve`, `noprune`, `MARK_DEBUG`) | Signal Tap, ILA |
| Wyzwolenie sprawdzane po zebraniu próbek sprzed wyzwolenia | pre-trigger |
| Analizator zmienia rozmieszczenie — błąd czasowy może zniknąć lub się pojawić | projekty na granicy timingu |
| Kwalifikator zapisu / bufor segmentowy wydłużają okno obserwacji | rzadkie zdarzenia |

## [17.03 — In-System Sources and Probes, VIO i JTAG-to-Avalon](17.03-in-system-sources-and-probes-vio-i-jtag-to.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| ISSP: sondy do 511 bitów, `instance_id` 4 znaki | `altsource_probe` |
| Każda transakcja JTAG to milisekundy — do sterowania i statusu, nie do strumieni | planowanie debugowania |
| `enable_metastability = "YES"` i `source_clk` = zegar odbiorcy źródeł | źródła ISSP |
| Wartości wielobitowe: odczyt do zgodności, protokół „dane → impuls zapisu” | brak atomowości ISSP |
| Najstarszy bit po lewej w ciągach bitów `read_probe_data`/`write_source_data` | skrypty Tcl |
| Wiele rejestrów → mostek JTAG-to-Avalon/AXI + System Console/Hardware Manager | testy peryferiów |
| Rdzenie debug usuwa się lub zabezpiecza w wersji produkcyjnej | bezpieczeństwo |

## [17.04 — Pomiary zewnętrzne: oscyloskop, analizator logiczny, integralność sygnałów](17.04-pomiary-zewnetrzne-oscyloskop-analizator.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| BW ≈ 0,35 / t_r; oscyloskop 100 MHz ≈ 3,5 ns | wybór przyrządu |
| t_widziany = √(t_s² + t_osc² + t_sondy²); przyrząd 3 × szybszy → błąd ok. 5 % | pomiar zboczy |
| Próbkowanie oscyloskopu ≥ 2,5–5 × pasmo | ustawienia |
| Przewód masy 15 cm + 10 pF → dzwonienie ok. 130 MHz; sprężynka masy | sondy |
| Linia długa, gdy opóźnienie > t_r / 6; FR4 ok. 15 cm/ns → 2,5 cm dla 1 ns | integralność sygnałów |
| O odbiciach decyduje czas narastania, nie częstotliwość | integralność sygnałów |
| Analizator w trybie czasowym ≥ 4 × (lepiej 10 ×) częstotliwość sygnału | analizatory USB |
| Najniższy prąd wyjściowy i najwolniejsze zbocze, które spełniają timing | ustawienia I/O FPGA |

## [17.05 — Działa w symulacji, nie działa na płytce — typowe przyczyny](17.05-dziala-w-symulacji-nie-dziala-na-plytce-typowe.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Cztery grupy przyczyn: inny układ po syntezie, timing, świat zewnętrzny, podłączenie | diagnoza |
| Najpierw najtańsze: piny, standardy, polaryzacja, zegary, wersja bitstreamu | kolejność |
| `@(*)` / `process (all)`, bez `#` w RTL, `default` zamiast `full_case`, `<=` w blokach taktowanych | styl kodu |
| Reset dla rejestrów sterujących — X w symulacji RTL bywa „optymistyczny” | reset |
| Ostrzeżenia syntezy (zatrzaski, sygnały bez sterownika) czytane przy każdej kompilacji | synteza |
| Błąd zależny od temperatury, ziarna lub dodania sondy → timing lub CDC | diagnoza |
| Błąd ze sprzętu odtworzony w symulacji → test regresyjny | naprawa |
