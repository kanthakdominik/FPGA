# Ściąga — 01 — Logika cyfrowa dla projektanta FPGA

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [01.01 — Systemy liczbowe, kody i liczby ze znakiem](01.01-systemy-liczbowe-kody-i-liczby-ze-znakiem.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| $N$ bitów: bez znaku $0 \dots 2^N-1$, U2 $-2^{N-1} \dots 2^{N-1}-1$ | zawsze |
| Suma dwóch liczb $N$-bitowych: $N+1$ bitów; iloczyn $N \times M$: $N+M$ bitów | szerokość wyniku bez utraty informacji |
| Negacja w U2: odwróć bity i dodaj 1 | U2; nie działa dla $-2^{N-1}$ |
| Poszerzanie: U2 powiela bit znaku, bez znaku dopisuje zera | zmiana szerokości |
| Przepełnienie U2: składniki o tym samym znaku, wynik o innym | dodawanie i odejmowanie ze znakiem |
| Binarny → Gray: `g = b ^ (b >> 1)` | liczniki przekraczające domeny zegara |
| 1 cyfra szesnastkowa = 4 bity | zapis stałych |
| Verilog: liczba bez rozmiaru (`5`, `'hA`) ma 32 bity | zawsze sprawdzaj szerokość stałych |

## [01.02 — Algebra Boole'a i minimalizacja — co z tego robi syntezator](01.02-algebra-boole-a-i-minimalizacja-co-z-tego-robi.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| LUT o $k$ wejściach realizuje dowolną funkcję $k$ zmiennych w jednym poziomie | MAX 10: $k = 4$; nowe rodziny: $k = 6$ |
| Koszt logiki w FPGA = liczba wejść i liczba poziomów LUT, nie liczba bramek | szacowanie zasobów i timingu |
| Drzewo AND/OR/XOR $n$ bitów: $\lceil \log_k n \rceil$ poziomów | szerokie porównania, parzystość, dekodery adresów |
| De Morgan: $\overline{ab} = \overline{a} + \overline{b}$, $\overline{a+b} = \overline{a}\,\overline{b}$ | sygnały aktywne niskim stanem |
| Hazardy są nieszkodliwe, jeśli wynik trafia do przerzutnika z tym samym zegarem | projekt synchroniczny |
| Nigdy nie steruj zegarem ani resetem asynchronicznym z logiki kombinacyjnej | zawsze |

## [01.03 — Bloki kombinacyjne: multipleksery, dekodery, enkodery, komparatory](01.03-bloki-kombinacyjne-multipleksery-dekodery.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Proces kombinacyjny: każde wyjście dostaje wartość w każdej ścieżce — najprościej przez wartości domyślne na początku | `process (all)`, `always @*`, `always_comb` |
| Multiplekser 4:1 = 2 LUT4 lub 1 LUT6 na bit | szacowanie zasobów |
| Priorytet tworzy kolejność `if … else if` (albo ostatnie przypisanie w pętli), nie `case` | enkodery, arbitry |
| Porównanie `<`, `>` idzie na łańcuch przeniesień; `==` na drzewo LUT | komparatory |
| Małe układy kombinacyjne testuj wyczerpująco — wszystkie kombinacje wejść | do ok. 20 bitów wejścia |

## [01.04 — Układy arytmetyczne: sumatory, przeniesienia, mnożenie](01.04-uklady-arytmetyczne-sumatory-przeniesienia.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| $s = a \oplus b \oplus c_{in}$, $c_{out} = ab + c_{in}(a \oplus b)$ | sumator pełny |
| W FPGA pisz `a + b` — narzędzie użyje łańcucha przeniesień; nie projektuj CLA ręcznie | sumatory do kilkudziesięciu bitów |
| MAX 10: 1 LE na bit sumatora lub licznika | szacowanie zasobów |
| $a - b = a + \overline{b} + 1$ | odejmowanie w U2 |
| Przepełnienie U2: $V = c_W \oplus c_{W-1}$ | flagi ALU |
| Mnożarka MAX 10: 18 × 18 lub dwie 9 × 9 w jednym bloku; 10M50 ma 144 bloki | mnożenie |
| Iloczyn $N \times M$ bitów ma $N + M$ bitów | szerokość wyniku |
| Nie używaj `/` i `%` ze zmiennym dzielnikiem w logice kombinacyjnej | dzielenie |

## [01.05 — Przerzutniki, zatrzaski i rejestry](01.05-przerzutniki-zatrzaski-i-rejestry.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Zatrzask — wrażliwy na poziom; przerzutnik — na zbocze | zawsze |
| W procesie taktowanym przypisania nieblokujące `<=`, w kombinacyjnym blokujące `=` | Verilog, SystemVerilog |
| Reset asynchroniczny: na liście czułości, sprawdzany przed zboczem zegara | wszystkie języki |
| Zwolnienie resetu asynchronicznego musi być zsynchronizowane z zegarem | każdy reset asynchroniczny |
| Ostrzeżenie *Inferred latch* = błąd w kodzie | Quartus, Vivado, Yosys |
| Zezwolenie zapisu zamiast osobnego, wolniejszego zegara | spowalnianie części układu |
| MAX 10: rejestr w każdym LE, wartość po konfiguracji 0 | szacowanie zasobów, wartości początkowe |

## [01.06 — Parametry czasowe: propagacja, setup, hold, clock-to-out](01.06-parametry-czasowe-propagacja-setup-hold-clock.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Setup: $t_{co} + t_{logic} + t_{route} + t_{su} \le T + t_{skew} - t_{unc}$ | ścieżki rejestr → rejestr |
| Hold: $t_{co,min} + t_{logic,min} + t_{route,min} \ge t_h + t_{skew}$ | ścieżki rejestr → rejestr |
| Naruszenia hold nie naprawi wolniejszy zegar | zawsze |
| Zapas (*slack*) = czas wymagany − czas przybycia; ujemny = błąd | raporty czasowe |
| Ścieżka bez ograniczenia nie jest sprawdzana | każdy projekt — sprawdzaj *Unconstrained Paths* |
| Setup sprawdzaj w modelu wolnym, hold w szybkim; projekt musi przejść wszystkie | Quartus, MAX 10 |
| 50 MHz → 20 ns, 100 MHz → 10 ns, 200 MHz → 5 ns | szybkie przeliczanie okresów |

## [01.07 — Metastabilność — pierwsze spotkanie](01.07-metastabilnosc-pierwsze-spotkanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każdy sygnał asynchroniczny przechodzi przez synchronizator co najmniej dwuprzerzutnikowy | przyciski, wejścia zewnętrzne, przejścia między domenami zegara |
| Między przerzutnikami synchronizatora nie ma logiki | zawsze |
| Synchronizator przenosi jeden bit; magistrale — kod Graya, uzgadnianie, FIFO | moduł 15 |
| $MTBF = e^{t_r/\tau} / (T_0 f_{clk} f_{data})$ — czas rozstrzygania w wykładniku | ocena synchronizatorów |
| Każde $\tau$ zapasu mnoży MTBF przez $e$ | szybkie szacowanie |
| Symulacja RTL nie pokazuje metastabilności | weryfikacja — potrzebny przegląd kodu i analiza CDC |
| Asynchroniczny reset: ustawienie asynchroniczne, zwolnienie zsynchronizowane | każdy reset asynchroniczny |

## [01.08 — Automaty skończone na papierze: Moore i Mealy](01.08-automaty-skonczone-na-papierze-moore-i-mealy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Moore: wyjście = f(stan); Mealy: wyjście = f(stan, wejścia) | zawsze |
| Mealy reaguje w tym samym takcie, Moore — o takt później | projektowanie protokołów |
| Z każdego stanu przejście dla każdej kombinacji wejść | diagram stanów |
| $n$ stanów: binarnie $\lceil \log_2 n \rceil$ bitów, 1 z n — $n$ bitów | kodowanie stanów |
| W FPGA domyślnie 1 z n — przerzutniki są tanie, dekodowanie szybkie | małe i średnie automaty |
| Wejście asynchroniczne do automatu — tylko przez synchronizator | zawsze ([01.07](01.07-metastabilnosc-pierwsze-spotkanie.md)) |
| Gałąź `others`/`default` nie czyni automatu bezpiecznym | automaty o wysokich wymaganiach niezawodności |
