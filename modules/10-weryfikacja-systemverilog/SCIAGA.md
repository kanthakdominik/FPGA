# Ściąga — 10 — Weryfikacja w SystemVerilogu

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [10.01 — Programowanie obiektowe: klasy, dziedziczenie, polimorfizm](10.01-programowanie-obiektowe-klasy-dziedziczenie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `t2 = t1` kopiuje uchwyt, nie obiekt | każde przypisanie obiektów |
| `new p1` — kopia płytka; głęboka — własna metoda `clone()`/`copy()` | obiekty z polami-uchwytami |
| Metody, które potomek może zmienić, deklaruj jako `virtual` w klasie bazowej | projekt klas testbencha |
| Ograniczenie o tej samej nazwie w potomku zastępuje ograniczenie rodzica | warianty transakcji |
| `$cast` zwraca 0 przy nieudanym rzutowaniu w dół — sprawdzaj wynik | rzutowanie |
| Monitor tworzy nowy obiekt dla każdej transakcji | przekazywanie przez skrzynki |
| Klasy nie są syntezowalne | cały moduł 10 |

## [10.02 — Losowanie z ograniczeniami (constrained random)](10.02-losowanie-z-ograniczeniami-constrained-random.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Sprawdzaj wynik `randomize()` — 0 oznacza brak rozwiązania i niezmienione pola | każde losowanie |
| Losowanie jest równomierne po **rozwiązaniach**, nie po zmiennych | ograniczenia warunkowe |
| `solve a before b` zmienia rozkład, nie zbiór rozwiązań | rzadkie tryby |
| `:=` — waga każdej wartości; `:/` — waga całego zakresu | `dist` |
| `dist` dopuszcza tylko wartości z listy | `dist` bez pełnej listy |
| Ograniczenie twarde wygrywa z `soft` | wartości domyślne nadpisywane przez test |
| Test statystyczny: ±4σ, σ = √(*Np*(1−*p*)) | sprawdzanie rozkładów |
| Verilator: ograniczenia od 5.026 (+ `z3`), pokrycie od 5.050 | narzędzia open source |

## [10.03 — Pokrycie funkcjonalne: covergroup, coverpoint, cross](10.03-pokrycie-funkcjonalne-covergroup-coverpoint.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Model pokrycia wynika ze specyfikacji, nie z kodu RTL | projekt modelu |
| Kosze: klasy równoważności i wartości brzegowe, nie wszystkie wartości | szerokie dane |
| Krzyżowanie: liczba koszy = iloczyn — tylko kombinacje, które mają znaczenie | `cross` |
| Kosz nieosiągalny → `ignore_bins` albo `iff`; niedozwolony → `illegal_bins` | dokładny wynik |
| Dziura w pokryciu → zmień ograniczenia albo dopisz test, nie zwiększaj tylko liczby losowań | zamykanie pokrycia |
| Próbkuj transakcję **sprawdzoną** (po porównaniu w scoreboardzie) | pokrycie ma znaczyć „sprawdzone” |
| Verilator: `covergroup` od 5.050 | narzędzia open source |

## [10.04 — Asercje SVA: sekwencje i właściwości](10.04-asercje-sva-sekwencje-i-wlasciwosci.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `|->` — następnik od tego samego taktu; `|=>` — od następnego (= `|-> ##1`) | implikacja |
| Asercja próbkuje wartości sprzed zbocza | asercje współbieżne |
| Pusty sukces: poprzednik nie zaszedł → asercja spełniona; do każdej ważnej asercji `cover` | czy asercja coś sprawdza |
| `disable iff (rst)` przerywa sprawdzanie asynchronicznie; reset sprawdzaj osobną asercją bez niego | reset |
| `assume` — obowiązki otoczenia; `assert` — obowiązki układu | podział odpowiedzialności |
| `bind` — asercje bez zmiany kodu RTL | asercje dla cudzego lub syntezowanego kodu |
| Verilator: `--assert`; liczniki w `cover` — `--coverage-user` | symulacja open source |

## [10.05 — Testbench warstwowy: driver, monitor, scoreboard](10.05-testbench-warstwowy-driver-monitor-scoreboard.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Jeden komponent — jedna odpowiedzialność; sygnały widzą tylko driver i monitor | architektura testbencha |
| Monitor nie korzysta z wiedzy drivera | niezależność sprawdzania |
| Klasy dostają sygnały przez wirtualny interfejs | klasy a moduły |
| `clocking`: `input #1step` — wartość sprzed zbocza; `output #1` — zmiana po zboczu | brak wyścigów |
| Scoreboard: kolejka przewidywań, porównanie w kolejności; na końcu kolejka pusta | potoki dowolnej głębokości |
| Koniec testu: wszystko wysłane i sprawdzone albo limit czasu (= błąd) | zawieszenia, zgubione wyniki |
| Wstrzykiwanie błędów (`BUG`) sprawdza, czy testbench je wykrywa | ocena jakości testbencha |

## [10.06 — Komunikacja i współbieżność: mailbox, semafory, zdarzenia, fork-join](10.06-komunikacja-i-wspolbieznosc-mailbox-semafory.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `join` — wszystkie, `join_any` — pierwsza (reszta biegnie), `join_none` — żadna | `fork` |
| `disable fork` kończy wszystkich potomków procesu, także z wcześniejszych `join_none` | sprzątanie |
| W gałęziach `join_none` w pętli — kopia `automatic` zmiennej pętli | uruchamianie wielu procesów |
| `mailbox(n)` blokuje `put` przy *n* elementach — przeciwciśnienie | generator → driver |
| `@ev` może przegapić wyzwolenie z tego samego kroku; `wait(ev.triggered)` — nie | zdarzenia |
| Każde czekanie bez gwarancji końca — ze strażą czasu | koniec testu |

## [10.07 — Plan weryfikacji i pokrycie kodu](10.07-plan-weryfikacji-i-pokrycie-kodu.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każda funkcja specyfikacji: sposób sprawdzenia + miara + stan | plan weryfikacji |
| Kryterium zakończenia zapisane liczbami przed rozpoczęciem | *sign-off* |
| Pokrycie funkcjonalne i kodu — oba; łączone z wszystkich testów i ziaren | zamykanie pokrycia |
| Dziura nieosiągalna → wyłączenie z uzasadnieniem, nie test | pokrycie kodu |
| 100 % pokrycia kodu ≠ poprawność | interpretacja |
| Verilator: `--coverage`, `verilator_coverage --write/--report/--annotate/--write-info` | narzędzia open source |
