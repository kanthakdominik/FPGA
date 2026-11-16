# Ściąga — 09 — Symulacja i testbenche

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [09.01 — Jak działa symulator: zdarzenia, delta cykle, regiony planowania](09.01-jak-dziala-symulator-zdarzenia-delta-cykle.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| VHDL: sygnał zmienia się w następnym delta cyklu, zmienna od razu | procesy |
| Verilog: `<=` aktualizowane w regionie NBA, po wszystkich zdarzeniach aktywnych | bloki taktowane |
| W blokach taktowanych `<=`, w kombinacyjnych `=` — inaczej wyścigi | Verilog, SV |
| VHDL: nie przypisuj zegara do innego sygnału (delta cykl opóźnienia = wyścig danych) | VHDL |
| SV: testbench w regionach reaktywnych (`program`, `clocking`) — bez wyścigów z układem | testbenche SV |
| Delta cykle nie przesuwają czasu symulacji | wszystkie symulatory zdarzeniowe |

## [09.02 — Pierwszy testbench: zegar, reset i pobudzenia](09.02-pierwszy-testbench-zegar-reset-i-pobudzenia.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Pobudzenia na zboczu opadającym (albo `#1` po narastającym), sprawdzenia po ustaleniu wyjść | testbenche bez `clocking` |
| Testbench kończy się jednoznacznie: `PASS` albo `FAIL: N` i zatrzymaniem symulacji | automatyzacja |
| Stan po resecie i reset w trakcie pracy — dwa osobne przypadki | każdy układ z resetem |
| floor(x / 4) ≠ obcięcie dla liczb ujemnych (−30,25 → −31, nie −30) | arytmetyka ze znakiem |
| Procedury/zadania dla powtarzalnych sekwencji | czytelność testbencha |

## [09.03 — Testbench samosprawdzający: model referencyjny i porównanie](09.03-testbench-samosprawdzajacy-model-referencyjny-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Model referencyjny inną metodą niż układ | każdy testbench z modelem |
| Losowe pobudzenia + model + porównanie w każdym takcie + pokrycie + podsumowanie | wzorzec testbencha |
| Test losowy kończy się sprawdzeniem pokrycia przypadków brzegowych | zawsze |
| Stałe ziarno — błąd powtarzalny | debugowanie |
| Przypadki wymagające sekwencji (4 skrajne próbki z rzędu) trzeba generować celowo | rozkład pobudzeń |

## [09.04 — Przebiegi: VCD, FST, GTKWave, Surfer i Questa](09.04-przebiegi-vcd-fst-gtkwave-surfer-i-questa.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| VCD — uniwersalny, duży; FST — skompresowany (tu ~9× mniejszy); GHW — pełne typy VHDL | wybór formatu |
| Przebiegi na żądanie (plusarg, makro, opcja), nie zawsze | testy w CI, długie symulacje |
| Debugowanie: od pierwszej rozbieżności wstecz do przyczyny | analiza błędu |
| Zapisuj widoki (`.gtkw`, `.do`) | powtarzalne debugowanie |
| Liczby ze znakiem jako *Signed Decimal*, stany jako nazwy | czytelność przebiegów |

## [09.05 — Wektory testowe z plików](09.05-wektory-testowe-z-plikow.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Model w języku wysokiego poziomu → plik wektorów → testbench HDL porównuje takt po takcie | algorytmy DSP, obraz, protokoły |
| Wiersz = takt, wejścia i oczekiwane wyjścia razem, komentarze z opisem sekcji | format wektorów |
| Plik generowany skryptem, w repozytorium; CI sprawdza aktualność | powtarzalność |
| Testbench liczy wektory i wymaga minimalnej liczby | ochrona przed pustym plikiem |
| Ścieżki względem katalogu roboczego symulatora | uruchamianie testów |

## [09.06 — Symulacja po syntezie i z opóźnieniami](09.06-symulacja-po-syntezie-i-z-opoznieniami.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| RTL — funkcja; po syntezie — zgodność syntezy z RTL; czasy — analiza statyczna | podział weryfikacji |
| MAX 10 w Quartusie: tylko netlista funkcjonalna (ostrzeżenie 10905), bez SDF | DECA |
| Symulacja czasowa netlisty: tylko starsze rodziny Intela; ogólnie zastąpiona przez STA | FPGA dziś |
| Testbench sprawdza układ przez porty — działa na RTL i netliście | projekt testbencha |
| Opóźnienia `#` w RTL syntezator ignoruje | kod syntezowalny |

## [09.07 — Regresja i automatyzacja: skrypty, Makefile, CI](09.07-regresja-i-automatyzacja-skrypty-makefile-ci.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każdy test: jednoznaczny wynik (`PASS`/`FAIL`) i kod wyjścia | automatyzacja |
| Czysty katalog i limit czasu na test | regresja |
| Regresja przy każdej zmianie: minuty; długie testy — osobno, rzadziej | CI |
| Wersje narzędzi w logu, stałe ziarna | powtarzalność |
| Makefile: `?=` dla parametrów, `abspath`, `wildcard`/`filter-out`, `.PHONY` | skrypty symulacji |
| Artefakty (przebiegi, raporty) z CI do pobrania | analiza błędów z CI |
