# Ściąga — 16 — Wydajność, zasoby i pobór mocy

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [16.01 — Potokowanie i retiming](16.01-potokowanie-i-retiming.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| k odcinków → f_max ≈ k ×, latencja + (k − 1), przepustowość = f_max | potokowanie |
| Drzewo 8 × 16 bitów na ECP5: 128 → 293 MHz za 2 stopnie potoku | przykład z modułu |
| Sygnał ważności przesuwany równo z danymi; rejestry danych bez resetu | każdy potok |
| Rejestr w pętli sprzężenia zmienia funkcję — potrzebna zmiana algorytmu | akumulatory, automaty |
| Retiming nie zmienia latencji; blokują go reset, wartość początkowa, CE, twarde bloki | retiming |
| Rejestry „do przesunięcia” stawiaj na wyjściu bloku, bez resetu | projekt pod retiming |

## [16.02 — Współdzielenie zasobów i kompromis powierzchnia–szybkość](16.02-wspoldzielenie-zasobow-i-kompromis.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Liczba zasobów k = ⌈operacje na wynik · przepustowość / f_zegara⌉ | dobór architektury |
| Współdzielenie w czasie: N × mniej zasobów, N × mniejsza przepustowość, + sterowanie i multipleksery | folding |
| Operacje wykluczające się: jedna jednostka + multipleksery argumentów, bez straty przepustowości | `sel ? a*b : c*d` |
| Nie współdziel tanich operacji — multiplekser kosztuje tyle co operacja | dodawanie, porównanie |
| DSP, RAM, LUT to osobne budżety — oszczędzaj ten, którego brakuje | każdy projekt |
| Automatyczne współdzielenie zależy od narzędzia i przebiegu — sprawdź w raporcie (tu 1469 vs 752 LUT4) | synteza |
| MAX 10 10M50: 144 mnożarki 18 × 18 | DECA |

## [16.03 — Fanout, duplikacja rejestrów i głębokość logiki](16.03-fanout-duplikacja-rejestrow-i-glebokosc-logiki.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Łańcuch n − 1 poziomów, drzewo ⌈log₂ n⌉ | operacje łączne |
| Maksimum z 16 bajtów na ECP5: łańcuch 21 MHz, drzewo 73 MHz | przykład z modułu |
| Synteza scala identyczne rejestry — ręczna duplikacja wymaga `dont_merge`/`DONT_TOUCH` | duplikacja |
| Lepiej ograniczenie fanoutu w narzędziu (`maxfan`, `MAX_FANOUT`) niż ręczne kopie | duże wachlarze |
| Duży fanout szkodzi, gdy odbiorcy są daleko i sygnał przechodzi przez logikę | diagnoza |
| Warunki liczone takt wcześniej i rejestrowane | skracanie logiki |
| Sygnał późny — na ostatnim multiplekserze | skracanie logiki |

## [16.04 — Zamykanie timingu: metodyka krok po kroku](16.04-zamykanie-timingu-metodyka-krok-po-kroku.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Kolejność: ograniczenia → diagnoza → RTL → ustawienia narzędzia → ziarna | każde zamykanie timingu |
| Udział połączeń > ok. 50–60 % ścieżki → problem rozmieszczenia/fanoutu, nie logiki | diagnoza |
| Rozrzut f_max między ziarnami: kilka–kilkanaście % (tu 8,9 %) | porównywanie wersji |
| Porównuj rozkłady z kilku ziaren, nie pojedyncze kompilacje | ocena zmian |
| Timing zamknięty tylko jednym ziarnem = brak marginesu | ocena ryzyka |
| Zapas w fazie rozwoju: ograniczenia 5–10 % ciaśniejsze | planowanie |
| Hold: naprawia narzędzie; duże naruszenia = problem z zegarem | hold |

## [16.05 — Floorplanning i ograniczenia fizyczne](16.05-floorplanning-i-ograniczenia-fizyczne.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Najpierw rozmieszczenie bez ograniczeń i jego obejrzenie, potem obszary | każdy floorplan |
| Obszary dla bloków (hierarchii), nie dla pojedynczych komórek | Logic Lock, Pblock |
| Zajętość obszaru do ok. 70–80 % | rozmiar obszaru |
| Połączenie przez cały ECP5-25: ok. +1,7 ns (f_max 299 → 200 MHz) | przykład z modułu |
| Bloki przy swoich pinach, pamięciach i kolumnach DSP | rozmieszczenie interfejsów |
| Rejestry w buforach I/O dla powtarzalnych czasów wejść i wyjść | interfejsy |
| Obszar ocenia się po całym rozkładzie zapasów, nie po jednej ścieżce | ocena skutku |

## [16.06 — Pobór mocy: statyczny i dynamiczny, szacowanie i redukcja](16.06-pobor-mocy-statyczny-i-dynamiczny-szacowanie-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| P = P_stat + P_dyn + P_I/O; P_dyn = Σ ½ · α · C · V² · f | każdy układ CMOS |
| Moc dynamiczna ∝ V² — obniżenie napięcia działa najsilniej | wybór układu, zasilanie |
| Quartus: domyślna aktywność 12,5 % dla sygnałów bez danych | Power Analyzer |
| Najdokładniej: VCD z symulacji netlisty z opóźnieniami (szpilki) | szacowanie |
| Izolacja argumentów przy danych co 4. takt: aktywność 3,65 × mniejsza | przykład z modułu |
| MAX 10 dwunapięciowy: rdzeń 1,2 V; tryb uśpienia: prąd rdzenia ok. −93 % (10M50) | DECA |
| Zegar: α = 2 w każdym takcie — wyłączanie zegara bloków daje najwięcej | redukcja |
| Statyczna rośnie z temperaturą — chłodzenie też obniża moc | projekt termiczny |
