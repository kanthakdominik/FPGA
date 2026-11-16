# Ściąga — 06 — SystemVerilog do projektowania

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [06.01 — logic, always_comb, always_ff i always_latch](06.01-logic-always-comb-always-ff-i-always-latch.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| W RTL: `logic`; `wire` tylko dla wielu sterowników | SystemVerilog |
| `always_comb` dla logiki kombinacyjnej, `always_ff` dla rejestrów, `always_latch` dla celowych zatrzasków | SystemVerilog |
| Zmienna przypisana w `always_comb`/`always_ff` nie może mieć innych sterowników | SystemVerilog |
| `always_comb` wykonuje się w chwili 0 i widzi sygnały czytane w funkcjach | symulacja |
| Styl dwóch bloków: `*_next` w `always_comb`, rejestry w `always_ff` | automaty, liczniki |

## [06.02 — Typy użytkownika: enum, struct, union, typedef i tablice spakowane](06.02-typy-uzytkownika-enum-struct-union-typedef-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| W RTL: `struct packed`, `union packed`, `enum` z typem bazowym `logic [N-1:0]` | SystemVerilog |
| Pierwsze pole struktury spakowanej = najstarsze bity | układ bitów |
| Pola unii spakowanej muszą mieć tę samą szerokość | SystemVerilog |
| Przypisanie liczby do `enum` wymaga rzutowania `typ'(x)` | kontrola typów |
| Luminancja BT.601 w 8 bitach: $(77R + 150G + 29B) \gg 8$ | przetwarzanie obrazu |
| Typy wspólne dla kilku modułów — w pakiecie | organizacja kodu |

## [06.03 — Pakiety i parametryzacja typami](06.03-pakiety-i-parametryzacja-typami.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Typy i stałe wspólne dla modułów — w pakiecie | organizacja kodu |
| Import w module (lub nagłówku modułu), nie w `$unit` | SystemVerilog |
| Pakiet kompilowany przed użytkownikami | kolejność plików |
| `parameter type T` + `$bits(T)` — bloki niezależne od typu danych | biblioteki bloków |
| Parametry typu nie wszędzie przechodzą syntezę — sprawdź narzędzie | Quartus Lite, starsze narzędzia |

## [06.04 — Interfejsy i modporty](06.04-interfejsy-i-modporty.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przesłanie: `valid = 1` i `ready = 1` na zboczu | AXI4-Stream, valid/ready |
| Nadawca nie cofa `valid` i nie zmienia `data` przed przesłaniem | AXI4-Stream |
| Nadawca nie czeka na `ready` z ustawieniem `valid` | brak zakleszczeń |
| Bufor skid: wszystkie wyjścia z rejestrów, 1 słowo/takt, 2 × rejestr danych | potoki strumieniowe |
| Interfejs + modporty zamiast list portów | SystemVerilog |

## [06.05 — unique, priority i bezpieczne instrukcje case](06.05-unique-priority-i-bezpieczne-instrukcje-case.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `unique` — dokładnie jedna gałąź; `unique0` — najwyżej jedna; `priority` — co najmniej jedna, z kolejnością | SystemVerilog |
| Nie używaj `full_case` / `parallel_case` — zastąp `unique` / `priority` | Verilog → SV |
| `case inside` zamiast `casez` i `casex` | SystemVerilog |
| `case (1'b1)` + `unique` — enkoder kodu 1 z n bez priorytetu | dekodowanie przydziałów |
| Arbiter karuzelowy: każdy klient czeka najwyżej N − 1 przydziałów | sprawiedliwy dostęp |

## [06.06 — Asercje natychmiastowe w kodzie RTL](06.06-asercje-natychmiastowe-w-kodzie-rtl.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `assert (warunek) else $error("…");` w blokach proceduralnych | SystemVerilog |
| W `always_comb` — `assert final` (odroczona) | unikanie fałszywych alarmów |
| Synteza pomija asercje — nie mogą zmieniać funkcji | RTL |
| Asercje w RTL: zakresy, zakazane kombinacje, 1 z n, brak `x` | projektant |
| Verilator: asercje działają z opcją `--assert` | symulacja |
| Test kończy się sprawdzeniem pokrycia przypadków brzegowych | każdy test losowy |

## [06.07 — Co z SystemVeriloga obsługują narzędzia syntezy](06.07-co-z-systemveriloga-obsluguja-narzedzia-syntezy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Rdzeń RTL (`logic`, `always_*`, `enum`, `struct packed`, pakiety) — bezpieczny we wszystkich narzędziach FPGA | SystemVerilog |
| Interfejsy, `parameter type`, `inside` — sprawdź w swoim narzędziu i wersji | SystemVerilog |
| Klasy, losowanie, pokrycie — tylko weryfikacja | SystemVerilog |
| Na granicy języków — porty z wektorami, bez typów użytkownika | projekty mieszane |
| Wątpliwość = mały przypadek testowy + raport syntezy | każda nowa konstrukcja |
