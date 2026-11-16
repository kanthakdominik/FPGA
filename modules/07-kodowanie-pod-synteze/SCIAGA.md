# Ściąga — 07 — Kodowanie pod syntezę — wzorce RTL

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [07.01 — Myślenie sprzętowe: kod HDL to schemat, nie program](07.01-myslenie-sprzetowe-kod-hdl-to-schemat-nie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Kod HDL opisuje schemat; wszystko działa równocześnie | zawsze w RTL |
| Pętla o stałych granicach = N kopii logiki | synteza |
| Kolejność instrukcji w bloku = kolejność multiplekserów (ostatnie przypisanie ma priorytet) | bloki proceduralne |
| Łańcuch: głębokość ~ N; drzewo: głębokość ~ log₂N | redukcje (max, suma, OR, XOR) |
| Opóźnienia `#`, `after`, `$display`, pętle o zmiennej liczbie obiegów — nie syntezują się | RTL |
| Wartości początkowe rejestrów syntezują się w FPGA, nie w ASIC | FPGA |
| Po syntezie porównaj raport z rysunkiem | każdy projekt |

## [07.02 — Rejestry i reset: synchroniczny, asynchroniczny, bez resetu](07.02-rejestry-i-reset-synchroniczny-asynchroniczny.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Reset ustawiany asynchronicznie, zdejmowany synchronicznie (synchronizator, 2 przerzutniki) | reset z zewnątrz |
| Jeden synchronizator resetu na domenę zegara | wiele zegarów |
| Resetuj sterowanie (stany, liczniki, `valid`), nie resetuj danych | FPGA |
| Wartości początkowe rejestrów działają w FPGA, nie w ASIC | przenośność |
| MAX 10: LAB ma 2 asynchroniczne czyszczenia, 1 synchroniczne czyszczenie, 1 synchroniczne ładowanie | upakowanie logiki |
| Reset danych blokuje wnioskowanie RAM, rejestrów przesuwnych w RAM i rejestrów w blokach DSP | 07.05–07.07 |

## [07.03 — Niezamierzone zatrzaski i pętle kombinacyjne](07.03-niezamierzone-zatrzaski-i-petle-kombinacyjne.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| W bloku kombinacyjnym przypisz każde wyjście na początku (wartości domyślne) | zawsze |
| `default` / `others` w każdym `case` bloku kombinacyjnego | zawsze |
| VHDL: `process (all)`; Verilog: `always @*`; SV: `always_comb` | logika kombinacyjna |
| Quartus 10240 (Verilog) i 10631 (VHDL) = zatrzask — poprawić | raport syntezy |
| Pętlę kombinacyjną przerywa rejestr | zawsze |
| `UNOPTFLAT` Verilatora może być pozorny (zależność bitów w jednym wektorze) — `split_var` | Verilator |

## [07.04 — Liczniki, dzielniki i clock enable](07.04-liczniki-dzielniki-i-clock-enable.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Nie dziel zegara logiką; jeden zegar + impulsy zezwolenia | wolne zdarzenia |
| Nowy zegar o innej częstotliwości — z PLL, nie z licznika | VGA, interfejsy |
| Szerokość licznika dla podziału przez N: ⌈log₂N⌉; 50 MHz → 100 Hz: 19 bitów | projektowanie liczników |
| Porównuj licznik ze stałą o tej samej szerokości | lint, czytelność |
| Kaskada: zezwolenie następnej cyfry = zezwolenie tej cyfry ∧ cyfra na maksimum | liczniki wielocyfrowe |
| Impuls zezwolenia z rejestru — dokładnie 1 takt, bez szpilek | `tick_gen` |

## [07.05 — Rejestry przesuwne, LFSR i linie opóźniające](07.05-rejestry-przesuwne-lfsr-i-linie-opozniajace.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przesunięcie = konkatenacja; kierunek jeden w całym projekcie | rejestry przesuwne |
| `load` ma priorytet nad `shift` | serializatory |
| Linia opóźniająca bez resetu i bez odczepów pośrednich — może trafić do pamięci | Quartus: *Auto Shift Register Replacement* |
| MAX 10: brak pamięci w LUT — linia to przerzutniki albo M9K | wybór długości linii |
| LFSR n-bitowy z wielomianem pierwotnym: okres 2ⁿ − 1 | generatory, testy |

## [07.06 — Wnioskowanie pamięci RAM i ROM](07.06-wnioskowanie-pamieci-ram-i-rom.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Pamięć blokowa wymaga odczytu synchronicznego (rejestr wyjścia lub adresu) | wnioskowanie RAM/ROM |
| Bez resetu zawartości pamięci | wnioskowanie RAM |
| Read-during-write: kod określa stare/nowe dane; sprawdź, czy blok to obsługuje | pamięci dwuportowe |
| M9K: 9216 bitów; 8K×1 … 256×36; prawdziwie dwuportowa do ×18 | MAX 10 |
| 10M50: 182 bloki M9K = 1638 Kbit | DECA |
| MAX 10 nie ma pamięci w LUT — odczyt asynchroniczny = przerzutniki | MAX 10 |
| ROM: `case` w bloku taktowanym, stała tablica, funkcja przy elaboracji | wnioskowanie ROM |

## [07.07 — Wnioskowanie mnożarek i bloków DSP](07.07-wnioskowanie-mnozarek-i-blokow-dsp.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10: blok = 1 × (18 × 18) albo 2 × (9 × 9); 10M50 — 144 bloki | DECA |
| MAX 10: brak sumatora/akumulatora w bloku — dodawanie w LE | MAC, filtry |
| Oba argumenty `signed` albo oba bez znaku | Verilog, SV |
| Iloczyn W × W ma 2W bitów; suma K iloczynów: + ⌈log₂K⌉ bitów | szerokości akumulatorów |
| Rejestry wejść i wyjścia mnożarki bez resetu | wnioskowanie bloków |
| Sterowanie (`valid`, `first`) płynie przez te same stopnie potoku co dane | potoki |

## [07.08 — Parametryzacja i projekt wielokrotnego użytku](07.08-parametryzacja-i-projekt-wielokrotnego-uzytku.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Parametry przez nazwę; nigdy `defparam` ani `` `define `` w roli parametru | instancje |
| Wielkości pochodne jako `localparam`/`constant`, nie parametry do ustawienia | projekt bloku |
| `$clog2` w Verilogu/SV; w VHDL własna funkcja całkowitoliczbowa | szerokości |
| Sprawdzaj dozwolone wartości parametrów przy elaboracji | bloki biblioteczne |
| Testuj na kilku zestawach parametrów, w tym skrajnych (N = 1 lub 2, W = 1) | bloki biblioteczne |
| Suma N liczb W-bitowych: W + ⌈log₂N⌉ bitów | sumatory, akumulatory |

## [07.09 — Styl kodu, lint i przeglądy: Verilator, Verible, VSG](07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Kod w repozytorium bez ostrzeżeń lintu; wyjątki wyłączone w kodzie z komentarzem | zespół |
| Wyłączenia w najmniejszym zakresie (linia, plik), nigdy całe kategorie globalnie | lint |
| Verilator `--lint-only -Wall` — semantyka; Verible — styl SV; VSG — styl VHDL | narzędzia open source |
| Lint w CI przy każdej zmianie, przed symulacją i syntezą | przepływ pracy |
| Formatowanie robi narzędzie, nie człowiek | przeglądy kodu |
