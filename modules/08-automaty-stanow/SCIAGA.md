# Ściąga — 08 — Automaty stanów i sterowanie

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [08.01 — Automat Moore'a i Mealy'ego w HDL — style kodowania](08.01-automat-moore-a-i-mealy-ego-w-hdl-style.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Moore: wyjście = f(stan); Mealy: wyjście = f(stan, wejścia) | projekt automatu |
| Mealy odpowiada o takt wcześniej, ale ma ścieżkę kombinacyjną wejście → wyjście | wybór typu |
| Styl dwuprocesowy: `state_next = state` i domyślne wyjścia na początku bloku | zapis HDL |
| Wyjścia sterujące czymś na zewnątrz — rejestrowane (styl trójprocesowy lub jednoprocesowy) | wyjścia z układu, sygnały zegarowe i resetu |
| N stanów w kodzie binarnym: ⌈log₂N⌉ przerzutników | szacowanie zasobów |

## [08.02 — Kodowanie stanów: binarne, one-hot, Graya](08.02-kodowanie-stanow-binarne-one-hot-graya.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Binarne: ⌈log₂N⌉ bitów; one-hot: N bitów; Johnson: ⌈N/2⌉ bitów | szacowanie zasobów |
| One-hot: test stanu = 1 bit, prosta logika następnego stanu; wiele kodów nielegalnych | FPGA (dużo przerzutników) |
| Gray: 1 bit zmiany między kolejnymi stanami (cyklicznie tylko dla 2ᵏ stanów) | moc, szpilki na wyjściach |
| Quartus: *State Machine Processing* (domyślnie *Auto*), atrybut `syn_encoding` | wymuszenie kodowania |
| Yosys: `fsm_encoding = "none"` wyłącza przekodowanie | porównania, kody użytkownika |
| Kodowanie ocenia się w raporcie syntezy, nie „z reguły” | każdy projekt |

## [08.03 — Bezpieczne automaty: stany nielegalne i odzyskiwanie](08.03-bezpieczne-automaty-stany-nielegalne-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Synchronizuj wejścia asynchroniczne przed automatem — to usuwa najczęstszą przyczynę stanów nielegalnych | zawsze |
| Gałąź `default`/`others` może zostać usunięta przez syntezę rozpoznanego automatu | bezpieczne automaty |
| Quartus: `syn_encoding = "safe"` / *Safe State Machine* — powrót ze stanu nielegalnego do stanu resetu | automaty wymagające odporności |
| One-hot: odległość Hamminga 2 — każde pojedyncze przekłamanie wykrywalne | detekcja SEU |
| Binarne/Graya: pojedyncze przekłamanie często daje inny legalny stan | ocena ryzyka |
| Porównania liczników defensywnie (`>=`), nie `==` | odporność na przekłamania |
| Wstrzykiwanie błędów (XOR do rejestru stanu) w testach | weryfikacja odzyskiwania |

## [08.04 — Eliminacja drgań styków i wykrywanie zboczy](08.04-eliminacja-drgan-stykow-i-wykrywanie-zboczy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Synchronizacja → filtracja → wykrycie zbocza, w tej kolejności | każde wejście mechaniczne |
| Drgania: setki µs do kilku ms; czas filtra 5–20 ms | przyciski, przełączniki |
| 10 ms przy 50 MHz = 500 000 taktów, licznik 19 bitów | DECA |
| Filtr zmienia poziom po N + 1 taktach stabilnego wejścia (w tym zapisie) | `debounce_fsm` |
| Impulsy `rise`/`fall` trwają 1 takt — do sterowania licznikami i automatami | wykrywanie zboczy |
| Wiele przycisków: wspólny impuls zezwolenia i małe liczniki | oszczędność zasobów |

## [08.05 — Handshake valid/ready i przepływ danych](08.05-handshake-valid-ready-i-przeplyw-danych.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przesłanie = `valid` ∧ `ready` na zboczu | valid/ready, AXI4-Stream |
| `valid` nie zależy od `ready`; raz ustawione — do przesłania, dane stabilne | źródło |
| `ready` może zależeć od `valid` | odbiorca |
| Pełna przepustowość wymaga przyjęcia nowych danych w takcie, w którym stare wychodzą | bloki potokowe |
| Kombinacyjna ścieżka `ready` przez kilka bloków — przerwij buforem skid | długie potoki |
| Test protokołu: losowe `valid` i `ready`, kontrola stabilności przy wstrzymaniu, liczenie przesłań | weryfikacja |

## [08.06 — Ścieżka danych i sterowanie (FSMD) — prosty procesor sekwencyjny](08.06-sciezka-danych-i-sterowanie-fsmd-prosty.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| FSMD = ścieżka danych (rejestry, ALU, multipleksery) + sterowanie (automat i sygnały sterujące) | bloki wielotaktowe |
| Sterowanie liczy sygnały kombinacyjnie; ścieżka danych zapisuje rejestry według tych sygnałów | zapis HDL |
| Status ze ścieżki danych (np. „wynik = 0”) wraca do sterowania | skoki warunkowe, pętle |
| Zezwolenie `step` zamiast osobnego zegara — praca ciągła, wolna i krokowa w tym samym układzie | debug, demonstracje |
| Weryfikacja procesora: interpreter listy instrukcji jako model, porównanie strumienia zdarzeń | procesory, akceleratory |
| `tiny_cpu`: 2 kroki na instrukcję, program 16 × 8 bitów w parametrze | ten temat |
