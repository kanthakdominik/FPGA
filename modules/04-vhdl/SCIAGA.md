# Ściąga — 04 — VHDL

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [04.01 — Struktura projektu: biblioteki, entity i architecture](04.01-struktura-projektu-biblioteki-entity-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każdy plik: `library ieee; use ieee.std_logic_1164.all;` i zwykle `use ieee.numeric_std.all;` | VHDL |
| Nigdy `std_logic_arith`, `std_logic_unsigned` — tylko `numeric_std` | VHDL |
| `entity` = interfejs, `architecture` = implementacja; kilka architektur dla jednej entity | VHDL |
| Instrukcje w architekturze są współbieżne; sekwencyjne tylko w procesie | VHDL |
| Instancja bezpośrednia: `u : entity work.nazwa generic map (…) port map (…)` | VHDL-93 i nowsze |
| `natural range 0 to N - 1` daje $\lceil \log_2 N \rceil$ bitów | porty i sygnały liczbowe |

## [04.02 — Typy: std_logic, wektory, numeric_std, integer, typy wyliczeniowe i rekordy](04.02-typy-std-logic-wektory-numeric-std-integer-typy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Porty `std_logic_vector`, arytmetyka na `unsigned`/`signed` | styl kodu VHDL |
| `unsigned(v)`, `signed(v)`, `std_logic_vector(x)` — zmiana typu bez kosztu | konwersje |
| `to_integer(x)`, `to_unsigned(i, N)`, `to_signed(i, N)` | liczba ↔ wektor |
| `resize`: `signed` powiela bit znaku, `unsigned` dopisuje zera | zmiana szerokości |
| `a + b` ma szerokość dłuższego argumentu, `a * b` — sumę szerokości | `numeric_std` |
| Agregat z wyborem zależnym od generic nie może stać obok `others` | stałe parametryzowane |

## [04.03 — Instrukcje współbieżne: przypisania, when-else, with-select](04.03-instrukcje-wspolbiezne-przypisania-when-else.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `when … else` — priorytet; `with … select` — wybór równoległy | logika kombinacyjna |
| `when … else` zawsze kończ gałęzią `else`; `with … select` — `when others` | brak zatrzasków, pełne pokrycie |
| Przypisanie współbieżne ≡ proces z pełną listą wrażliwości | semantyka |
| Kolejność instrukcji współbieżnych w pliku nie ma znaczenia | architektura |
| Jeden sygnał — jedno przypisanie współbieżne lub jeden proces | brak wielu sterowników |

## [04.04 — Procesy, lista wrażliwości, sygnały a zmienne](04.04-procesy-lista-wrazliwosci-sygnaly-a-zmienne.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Sygnał `<=` zmienia wartość po zawieszeniu procesu; zmienna `:=` — natychmiast | VHDL |
| Łańcuch przypisań sygnałów w procesie taktowanym = łańcuch rejestrów | sprzęt |
| Zmienna czytana przed zapisem w procesie taktowanym = rejestr | sprzęt |
| `process (all)` dla logiki kombinacyjnej | VHDL-2008 |
| Proces ma listę wrażliwości albo `wait`, nigdy oba | VHDL |
| Verilog: `<=` w blokach taktowanych, `=` w kombinacyjnych | Verilog, SV |

## [04.05 — Instrukcje sekwencyjne: if, case i pętle](04.05-instrukcje-sekwencyjne-if-case-i-petle.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `if/elsif` — priorytet; `case` — rozłączne stałe wybory | logika w procesach |
| `case` na `std_logic_vector` wymaga `when others` | VHDL |
| Pętla `for` jest rozwijana: N iteracji = N kopii logiki w jednym takcie | synteza |
| Liczba iteracji pętli musi być znana w czasie syntezy | synteza |
| Wartości domyślne przed `if`/`case` w procesie kombinacyjnym | brak zatrzasków |
| Verilog: konkatenacja blokuje poszerzanie argumentów do szerokości kontekstu | wyrażenia z `~` i przeniesieniem |

## [04.06 — Hierarchia: komponenty, instancjonowanie, generic i generate](04.06-hierarchia-komponenty-instancjonowanie-generic.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Instancja bezpośrednia `entity work.x` — domyślnie; komponent — gdy potrzebny | VHDL |
| Porty zawsze łączone nazwami, nigdy pozycyjnie | wszystkie języki |
| Bloki generate muszą mieć etykiety | VHDL, dobra praktyka w Verilogu i SV |
| Testuj skrajne wartości generic (0, 1, maksimum) | moduły parametryzowane |
| `natural` dla parametrów mogących być 0, `positive` dla ≥ 1 | generic |

## [04.07 — Pakiety, funkcje, procedury i atrybuty](04.07-pakiety-funkcje-procedury-i-atrybuty.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `package` — deklaracje, `package body` — treść; `use work.pkg.all` | VHDL |
| Funkcja w RTL = przepis na logikę wstawiany w każdym wywołaniu | synteza |
| Parametr bez ograniczeń + atrybuty `'length`, `'range`, `'high` = kod niezależny od szerokości | funkcje VHDL |
| Alias normalizujący `(x'length - 1 downto 0)` na początku funkcji | argumenty o dowolnych indeksach |
| Funkcja — tylko parametry `in`, bez `wait`; procedura — `out`, `inout`, `wait` | VHDL |
| Pakiety SV przed modułami na liście plików | kompilacja SV |

## [04.08 — VHDL-2008 i VHDL-2019 — co ułatwiają](04.08-vhdl-2008-i-vhdl-2019-co-ulatwiaja.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `process (all)`, czytanie portów `out`, `case?`, `?=`, redukcje `and v`/`xor v` — VHDL-2008 | nowy kod VHDL |
| Quartus: `VHDL_INPUT_VERSION VHDL_2008`; GHDL: `--std=08` | ustawienia narzędzi |
| `casez` w Verilogu dopasowuje `z` po obu stronach; w SV lepiej `case inside` | wartości obojętne |
| Przed użyciem generic typów i VHDL-2019 sprawdź obsługę w syntezie | przenośność kodu |

## [04.09 — Pułapki VHDL: rozdzielczość sygnałów, konwersje i delta cykle](04.09-pulapki-vhdl-rozdzielczosc-sygnalow-konwersje-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `unsigned` → `signed`: najpierw poszerz o bit (`resize`), potem zmień typ | konwersje |
| `std_logic_vector` porównuj liczbowo tylko po konwersji na `unsigned`/`signed` | porównania |
| `std_ulogic` dla sygnałów wewnętrznych wykrywa wielu sterowników przy kompilacji | VHDL |
| Nie przepisuj zegarów przypisaniem `clk_b <= clk` | RTL i testbenche |
| `rising_edge(clk)`, nie `clk'event and clk = '1'` | VHDL |
| Dzielenie `signed` zaokrągla do zera, przesunięcie arytmetyczne — w dół | arytmetyka |
