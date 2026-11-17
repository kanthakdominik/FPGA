# Ściąga — 11 — UVM — Universal Verification Methodology

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [11.01 — Po co metodologia: struktura środowiska UVM](11.01-po-co-metodologia-struktura-srodowiska-uvm.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Test → środowisko → agent (sekwencer, driver, monitor) + scoreboard, pokrycie | struktura środowiska |
| Agent = wszystko o jednym interfejsie; wielokrotnego użytku | podział kodu |
| Komponenty (`uvm_component`) — stałe, w hierarchii; obiekty (`uvm_object`) — dynamiczne | wybór klasy bazowej |
| Każda klasa z makrem `uvm_*_utils` i tworzona przez `type_id::create()` | fabryka |
| Test trwa, dopóki ktoś trzyma sprzeciw (`raise_objection`/`drop_objection`) | koniec testu |
| Jeden program, wiele testów: `+UVM_TESTNAME` | regresja |
| Verilator + uvm-core 2020.3.1 + `UVM_NO_DPI`: tylko `+UVM_TESTNAME` z argumentów `+UVM_…` | narzędzia otwarte |

## [11.02 — Komponenty, fazy i fabryka](11.02-komponenty-fazy-i-fabryka.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `build` z góry na dół; `connect`, `check`, `report` z dołu do góry; `run` równolegle | fazy |
| Tylko `run_phase` (i fazy szczegółowe) zużywają czas — reszta to funkcje | fazy |
| Podmiany w fabryce — przed utworzeniem obiektu (w `build_phase` testu, przed `super`) | fabryka |
| Nowy typ musi dziedziczyć po starym | fabryka |
| `type_id::create()` zamiast `new()` | wszystko, co ma być podmienialne |
| Metody, które potomek ma zmieniać — `virtual` | klasy do podmiany |

## [11.03 — Transakcje, sekwencje i sekwencer](11.03-transakcje-sekwencje-i-sekwencer.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Transakcja opisuje *co* (i losowany *sposób*), driver — *jak* na sygnałach | podział odpowiedzialności |
| `create` → `start_item` → `randomize` → `finish_item` | wysłanie transakcji |
| Driver: `get_next_item` → sterowanie → `item_done` | odbiór transakcji |
| Odpowiedź w tym samym obiekcie — gdy jedna transakcja w toku | proste protokoły |
| Sekwencja wirtualna koordynuje kilka sekwencerów | wiele interfejsów |
| `local::` w `randomize() with` — zmienna z zakresu wywołania | konflikty nazw |

## [11.04 — Agent, driver i monitor](11.04-agent-driver-i-monitor.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przesłanie = `VALID && READY` na zboczu; `VALID` nie zależy od `READY` | AXI, każdy kanał |
| AW i W niezależne; B po obu | zapis AXI |
| `RESP`: 00 OKAY, 10 SLVERR, 11 DECERR | odpowiedzi |
| Agent: aktywny = sekwencer + driver + monitor; pasywny = monitor | konfiguracja agenta |
| Monitor nie korzysta z wiedzy drivera; każda transakcja to nowy obiekt | niezależność |
| Driver wyrównuje się do zdarzenia `clocking` przed pierwszym zapisem | uniknięcie wyścigu |

## [11.05 — Scoreboard, porty analizy i pokrycie](11.05-scoreboard-porty-analizy-i-pokrycie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Monitor ma port analizy; odbiorcy podłączani w `connect_phase` środowiska | dystrybucja transakcji |
| `write()` to funkcja — bez czasu; przetwarzanie z czasem przez `uvm_tlm_analysis_fifo` | odbiorcy |
| Model w scoreboardzie niezależny od RTL i od RAL | niezależność sprawdzania |
| `uvm_subscriber #(T)` — najprostszy odbiorca (pokrycie, logger) | pokrycie |
| Komunikat błędu: transakcja + wartość otrzymana + oczekiwana | diagnostyka |

## [11.06 — Konfiguracja: uvm_config_db, testy i środowiska](11.06-konfiguracja-uvm-config-db-testy-i-srodowiska.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `set` przed `get`: zapis w `build_phase` rodzica, odczyt w `build_phase` dziecka | kolejność |
| `get` zwraca 0, gdy brak wpisu — sprawdzaj i zgłaszaj `uvm_fatal` dla wymaganych | odporność |
| Wyższy poziom hierarchii wygrywa; na tym samym poziomie — późniejszy zapis | priorytety |
| Obiekt konfiguracji zamiast wielu pojedynczych wpisów | większe środowiska |
| Typ w `set` i `get` musi być identyczny (`int` ≠ `int unsigned`) | częsty błąd |
| Parametry modułów — przy kompilacji (`-G`), nie przez `config_db` | parametry RTL |

## [11.07 — Model rejestrów (RAL)](11.07-model-rejestrow-ral.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Model: blok → rejestry → pola; mapa z adresami i sekwencerem; adapter do agenta | struktura RAL |
| Lustro aktualizuje predyktor z monitora (`set_auto_predict(0)`) | wiele masterów, ruch spoza modelu |
| `predict()` dla efektów ubocznych, których predyktor nie zna | rejestry zależne, flagi sprzętowe |
| Pola `volatile` nie są porównywane przez `mirror`, chyba że `set_compare(UVM_CHECK)` | rejestry stanu |
| Bit-bash z pominięciem rejestrów z efektami ubocznymi (`NO_REG_BIT_BASH_TEST`) | wbudowane sekwencje |
| Wbudowane sekwencje + testy funkcjonalne — oba potrzebne | plan weryfikacji |
| Model generowany ze specyfikacji (IP-XACT, SystemRDL) | projekty produkcyjne |

## [11.08 — Kompletny przykład: testbench UVM dla bloku z AXI4-Lite](11.08-kompletny-przyklad-testbench-uvm-dla-bloku-z.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Agent i interfejs — wielokrotnego użytku; środowisko, model, testy — dla bloku | podział kodu |
| Jedna kompilacja, wiele testów (`+UVM_TESTNAME`), wiele ziaren | regresja |
| Wstrzyknięte błędy z oczekiwanym wynikiem dla każdego testu | ocena testbencha |
| Dwa niezależne źródła sprawdzania (scoreboard, RAL) — mocniejsze niż jedno | jakość weryfikacji |
| Test zbiorczy wymaga pokrycia 100 % i zera błędów z każdego źródła | kryterium zakończenia |
