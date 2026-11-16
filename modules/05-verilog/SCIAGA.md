# Ściąga — 05 — Verilog

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [05.01 — Moduły, porty, wire i reg](05.01-moduly-porty-wire-i-reg.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `reg` = przypisywany w bloku proceduralnym; nie oznacza rejestru | Verilog |
| `wire` = sterowany przez `assign`, port lub instancję | Verilog |
| W SV: `logic` zamiast `wire` i `reg` | nowy kod |
| `` `default_nettype none `` na początku każdego pliku, `` `default_nettype wire `` na końcu | Verilog |
| Porty w stylu ANSI (Verilog-2001) | zawsze |
| W testbenchach `===` / `!==` | porównania z `x` i `z` |

## [05.02 — Operatory, liczby, rozmiar i znak](05.02-operatory-liczby-rozmiar-i-znak.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Szerokość wyrażenia = max(argumenty, lewa strona przypisania) | arytmetyka, bitowe, `?:` |
| Ze znakiem tylko, gdy **wszystkie** argumenty są ze znakiem | każde wyrażenie |
| Wycinki i konkatenacje są zawsze bez znaku | Verilog, SV |
| Liczba bez rozmiaru = 32 bity ze znakiem | stałe |
| `>>>` jest arytmetyczne tylko dla wyrażeń ze znakiem | przesunięcia |
| `x & (x - 1)` zeruje najmłodszą jedynkę; `x & -x` ją izoluje | sztuczki bitowe |
| Rozszerzenie znakiem: `{{N{x[W-1]}}, x}` | poszerzanie ręczne |

## [05.03 — assign i always: logika kombinacyjna i sekwencyjna](05.03-assign-i-always-logika-kombinacyjna-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `assign` → `wire`; `always` → `reg` | Verilog |
| `always @*` z `=`, `always @(posedge clk)` z `<=` | Verilog |
| Każdy sygnał przypisywany w jednym miejscu | wszystkie języki |
| Impuls jednego taktu: wartość domyślna na początku bloku taktowanego | sygnały sterujące |
| Debouncer: ok. 10 ms stabilności; przy 50 MHz licznik 19-bitowy | przyciski mechaniczne |
| Przerzutnik Schmitta na wejściu nie usuwa drgań styków | DECA, `KEY` |

## [05.04 — Przypisania blokujące i nieblokujące — reguły Cummingsa](05.04-przypisania-blokujace-i-nieblokujace-reguly.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Bloki taktowane — `<=`; kombinacyjne — `=` | Verilog, SV |
| Nie mieszaj `=` i `<=` w jednym bloku (wyjątek: lokalne zmienne tymczasowe w SV) | Verilog, SV |
| Jedna zmienna — jeden blok `always` | Verilog, SV |
| Kolejność wykonywania bloków `always` w tej samej chwili jest niezdefiniowana | symulacja |
| `$strobe` pokazuje wartości po przypisaniach nieblokujących | debugowanie |
| LFSR z wielomianem pierwotnym: okres $2^W - 1$ | generatory pseudolosowe |

## [05.05 — Parametry, localparam, generate i instancjonowanie](05.05-parametry-localparam-generate-i-instancjonowanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `parameter` — konfiguracja z zewnątrz; `localparam` — stała wewnętrzna | Verilog, SV |
| Nie używaj `defparam` | Verilog |
| Instancje: parametry i porty łączone nazwami | zawsze |
| Tablice przez porty: spłaszczenie `[N*W-1:0]` i `x[i*W +: W]` (Verilog), tablica spakowana (SV) | Verilog-2001, SV |
| PWM: $f_{PWM} = f_{clk} / 2^W$; 50 MHz, W = 8 → ok. 195 kHz | sterowanie jasnością, silnikami |
| Wyjście PWM z rejestru — bez szpilek | sygnały na pinach |

## [05.06 — Funkcje, zadania i dyrektywy kompilatora](05.06-funkcje-zadania-i-dyrektywy-kompilatora.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Funkcja: jedna wartość, bez czasu, syntezowalna; zadanie: argumenty wyjściowe, może czekać | Verilog, SV |
| `automatic` dla funkcji i zadań wywoływanych równocześnie lub rekurencyjnie | testbenche, pakiety SV |
| Stałe modułu — `parameter`, nie `` `define `` | styl |
| `` `define `` z prefiksem projektu i strażnikiem `` `ifndef `` | stałe globalne |
| CRC-8/SMBUS: wielomian 0x07, start 0, „123456789” → 0xF4 | testy CRC |
| Testuj algorytmy na publicznych wartościach kontrolnych | CRC, sumy kontrolne, szyfry |

## [05.07 — Pułapki Verilogu: niejawne sieci, obcinanie, znak i wyścigi](05.07-pulapki-verilogu-niejawne-sieci-obcinanie-znak.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `` `default_nettype none `` w każdym pliku Verilog | zawsze |
| Lint (`verilator --lint-only -Wall`) przed każdym commitem | praca zespołowa |
| Nie używaj `casex`, `full_case`, `parallel_case` | Verilog |
| `&&` / `\|\|` dla warunków, `&` / `\|` dla bitów | wyrażenia |
| Suma w uzupełnieniu do jedynki: 17-bitowa suma, przeniesienie dodane do bitu 0 | RFC 1071 |
| Wektory zawsze `[N-1:0]` (najstarszy bit po lewej) | konwencja |
