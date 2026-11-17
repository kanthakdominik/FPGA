# Ściąga — 12 — Weryfikacja z otwartymi narzędziami

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [12.01 — cocotb: testbench w Pythonie](12.01-cocotb-testbench-w-pythonie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Pobudzenia na `FallingEdge`, odczyt po `RisingEdge` + `ReadOnly()` | brak wyścigów |
| W fazie `ReadOnly` nie zapisuje się sygnałów | `ReadOnly` |
| `Clock(...).start()` bez `start_soon` (cocotb ≥ 2.0) | zegar |
| Wartości: `.to_signed()`, `.to_unsigned()` zamiast `int(...)` dla sygnałów ze znakiem | odczyt |
| Runner (`cocotb_tools.runner`) + JUnit `results.xml` | regresja i CI |
| Verilator z cocotb 2: wersja ≥ 5.036 | narzędzia |

## [12.02 — VUnit: testy jednostkowe dla VHDL i SystemVeriloga](12.02-vunit-testy-jednostkowe-dla-vhdl-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Testbench VUnit: nazwa `tb_*`, generic `runner_cfg`, `test_runner_setup` … `test_runner_cleanup` | rozpoznanie testów |
| Każdy `run("…")` — osobna symulacja (domyślnie) | izolacja testów |
| `add_config` — ten sam test z innymi generikami | warianty układu |
| `-p N` — N symulacji równolegle; `--xunit-xml` — raport dla CI | regresja |
| `test_runner_watchdog` — limit czasu symulacji | zawieszenia |
| SystemVerilog w VUnit — tylko symulatory komercyjne | wybór narzędzia |

## [12.03 — OSVVM i UVVM: metodologie dla VHDL](12.03-osvvm-i-uvvm-metodologie-dla-vhdl.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| OSVVM: zestaw pakietów; UVVM: biblioteka + architektura VVC | wybór metodologii |
| `RandCovPoint` — losowanie z niepokrytych koszy; pełne pokrycie bez powtórzeń | pokrycie OSVVM |
| `ReportAlerts` / `report_alert_counters(FINAL)` — jedno miejsce na wynik testu | raport |
| `await_value(sygnał, wartość, min, max, …)` — zdarzenie w oknie czasowym | UVVM |
| Po procedurze czekającej na zdarzenie — ponowna synchronizacja z rytmem pobudzeń | wszystkie testbenche |
| Obie biblioteki: GHDL i symulatory komercyjne, bez dodatkowych licencji | narzędzia |

## [12.04 — Verilator: szybka symulacja z C++](12.04-verilator-szybka-symulacja-z-c.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Verilator: HDL → C++ → kod maszynowy; `eval()` ustala stan dla bieżących wejść | model C++ |
| Dwa `eval()` na takt: wejścia przy `clk = 0`, potem `clk = 1` | testbench C++ |
| Logika dwuwartościowa — brak `X`/`Z`; inicjalizacja `--x-initial` | interpretacja wyników |
| Tylko Verilog/SystemVerilog | VHDL → GHDL |
| Tu: ~8 mln taktów/s (C++) vs ~25 tys. (Icarus) — kilkaset razy | rząd wielkości |
| Przebiegi tylko dla potrzebnego zakresu (spowalniają) | długie symulacje |

## [12.05 — Modele w Pythonie i porównanie bit w bit](12.05-modele-w-pythonie-i-porownanie-bit-w-bit.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Układ ↔ model bit w bit: równość; model ↔ ideał: tolerancja | dwa poziomy porównania |
| Zaokrąglenie do najbliższej: błąd ≤ ½ LSB; obcięcie: < 1 LSB i przesunięcie średniej | kwantyzacja |
| `int64` w modelu; `>>` = floor dla liczb ze znakiem | numpy |
| Szerokość sumy: wejście + współczynnik + log₂(liczba składników) | brak przepełnienia |
| Nasycenie osiągalne, gdy Σ\|h\| przekracza skalę wyjścia | testy brzegowe |
| Przypadki brzegowe arytmetyki liczone z modelu (statystyki pokrycia) | jakość testu |

## [12.06 — Ciągła integracja projektu HDL w GitHub Actions](12.06-ciagla-integracja-projektu-hdl-w-github-actions.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każdy krok kończy się kodem ≠ 0 przy błędzie | warunek działania CI |
| Wersje narzędzi i pakietów przypięte; aktualizacja = zmiana jednej linii | powtarzalność |
| Duże narzędzia w pamięci podręcznej z kluczem wersji | czas przebiegu |
| Testy z wstrzykniętymi błędami w CI — oczekiwane „FAIL” | jakość testbenchy |
| Wyniki w podsumowaniu zadania i jako artefakty | analiza bez logów |
| Narzędzia producenta i sprzęt — *self-hosted runner* | Quartus, płytka |
