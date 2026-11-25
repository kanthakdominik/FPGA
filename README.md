# FPGA — od bramki do systemu na chipie

**Wersja do czytania w przeglądarce (wzory, wyszukiwarka, menu modułów, kod w trzech językach przełączany zakładkami): [kanthakdominik.github.io/FPGA](https://kanthakdominik.github.io/FPGA/)**

[← Wszystkie bazy wiedzy](https://kanthakdominik.github.io/)

Otwarta baza wiedzy o projektowaniu układów FPGA, prowadząca od podstaw logiki cyfrowej do **poziomu zawodowego inżyniera FPGA**: projektowania RTL, weryfikacji (SystemVerilog, UVM, cocotb, metody formalne), analizy czasowej, przejść między domenami zegarowymi, interfejsów, systemów z procesorem i przygotowania do rozmowy kwalifikacyjnej.

Repozytorium jest pomyślane jako darmowy materiał dla każdego: studenta elektroniki lub informatyki, programisty, który chce przejść do sprzętu, i inżyniera, który chce uporządkować praktykę.

Zasady:

- **Treść jest po polsku**, nazwy w kodzie i terminy branżowe po angielsku (z polskim wyjaśnieniem przy pierwszym użyciu).
- **Trzy języki HDL.** Każdy przykład syntezowalny jest napisany w **VHDL**, **Verilogu** i **SystemVerilogu**, z testbenchem w każdym z nich. Weryfikacja zaawansowana (OOP, UVM) jest w SystemVerilogu, cocotb w Pythonie.
- **Kod niezależny od producenta**, a obok niego **implementacja na płytce [Arrow DECA](plytka-deca/README.md)** (Altera MAX 10, 10M50DAF484C6G) — z przypisaniami pinów, ograniczeniami czasowymi i skryptem tworzącym projekt w Quartusie.
- **Każdy testbench sam sprawdza wynik** i jest uruchamiany automatycznie przy każdym pushu (GHDL, Icarus Verilog, Verilator).
- **Źródła zewnętrzne są wyłącznie anglojęzyczne** — dokumentacja producentów, standardy, książki, kursy i artykuły ([RESOURCES.md](RESOURCES.md)).

---

## Jak korzystać z repozytorium

1. Przeczytaj [ROADMAP.md](ROADMAP.md) — kolejność modułów, zależności, ścieżki nauki (projektant RTL, weryfikacja, szybki start na DECA) i szacowany czas.
2. Zainstaluj narzędzia z [NARZEDZIA.md](NARZEDZIA.md) — wszystkie darmowe.
3. Przejrzyj [RESOURCES.md](RESOURCES.md) — książki, dokumentację i kursy, do których odwołują się tematy.
4. Poznaj płytkę: [plytka-deca/](plytka-deca/README.md).
5. Przerabiaj moduły. Każdy temat ma ten sam układ:

| Sekcja | Co zawiera |
|--------|------------|
| **Po co to jest** | Gdzie to spotkasz w projekcie i na rozmowie kwalifikacyjnej |
| **Intuicja** | Wyjaśnienie bez kodu, z analogią albo rysunkiem |
| **Teoria** | Pojęcia i zależności razem z warunkami stosowania |
| **Schemat i przebiegi** | Schemat blokowy i diagram czasowy |
| **Kod: VHDL / Verilog / SystemVerilog** | Ten sam układ w trzech językach, z omówieniem różnic |
| **Co powstaje po syntezie** | Schemat RTL, zużycie zasobów MAX 10, uwagi z raportu |
| **Weryfikacja** | Samosprawdzający się testbench i jak go uruchomić |
| **Na płytce DECA** | Moduł nadrzędny, piny, peryferia, jak sprawdzić działanie |
| **Reguły i liczby do zapamiętania** | Trafiają też do ściągi modułu |
| **Typowe pułapki** | Błędy, także te, które przechodzą symulację, a psują sprzęt |
| **Pytania rekrutacyjne** | Pytania jak na rozmowie technicznej, wzorcowe odpowiedzi pod `<details>` |
| **Zadania** | Obliczenia, „znajdź błąd w kodzie”, zadania projektowe |
| **Źródła** | Konkretne rozdziały i sekcje dokumentacji |

6. Do powtórki: każdy moduł ma **ściągę** (`SCIAGA.md`), a przed rozmową kwalifikacyjną są [pytania, zadania projektowe z rozwiązaniami i pułapki](rozmowa-kwalifikacyjna/README.md). Nieznane słowo sprawdzisz w [słowniczku](SLOWNICZEK.md).

### Oznaczenia

| Znak | Znaczenie |
|------|-----------|
| 🟢 | Podstawy — od tego zaczynasz |
| 🧩 | Projektowanie RTL |
| 🔍 | Weryfikacja |
| 🛠️ | Ćwiczenia i projekty na płytce DECA |
| 💼 | Temat częsty na rozmowach kwalifikacyjnych |

---

## Mapa modułów

<!-- mapa:start -->
### I. Fundamenty

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 00 | [Środowisko pracy i pierwszy projekt](modules/00-srodowisko-pracy/README.md) | 🟢🛠️ | 7 | 8 h |
| 01 | [Logika cyfrowa dla projektanta FPGA](modules/01-logika-cyfrowa/README.md) | 🟢🛠️💼 | 8 | 14 h |
| 02 | [Architektura układów FPGA](modules/02-architektura-fpga/README.md) | 🟢🛠️💼 | 10 | 12 h |
| 03 | [Przepływ projektowy od RTL do bitstreamu](modules/03-przeplyw-projektowy/README.md) | 🟢🛠️💼 | 7 | 10 h |

### II. Języki opisu sprzętu i wzorce RTL

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 04 | [VHDL](modules/04-vhdl/README.md) | 🧩💼 | 9 | 24 h |
| 05 | [Verilog](modules/05-verilog/README.md) | 🧩🛠️💼 | 7 | 18 h |
| 06 | [SystemVerilog do projektowania](modules/06-systemverilog-rtl/README.md) | 🧩💼 | 7 | 16 h |
| 07 | [Kodowanie pod syntezę — wzorce RTL](modules/07-kodowanie-pod-synteze/README.md) | 🧩🛠️💼 | 9 | 20 h |
| 08 | [Automaty stanów i sterowanie](modules/08-automaty-stanow/README.md) | 🧩🛠️💼 | 6 | 14 h |

### III. Weryfikacja

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 09 | [Symulacja i testbenche](modules/09-symulacja-i-testbench/README.md) | 🔍💼 | 7 | 16 h |
| 10 | [Weryfikacja w SystemVerilogu](modules/10-weryfikacja-systemverilog/README.md) | 🔍💼 | 7 | 24 h |
| 11 | [UVM — Universal Verification Methodology](modules/11-uvm/README.md) | 🔍💼 | 8 | 24 h |
| 12 | [Weryfikacja z otwartymi narzędziami](modules/12-weryfikacja-open-source/README.md) | 🔍 | 6 | 16 h |
| 13 | [Weryfikacja formalna](modules/13-weryfikacja-formalna/README.md) | 🔍💼 | 5 | 12 h |

### IV. Czas, zegary i implementacja

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 14 | [Statyczna analiza czasowa (STA)](modules/14-analiza-czasowa/README.md) | 🛠️💼 | 6 | 16 h |
| 15 | [Zegary, reset i przejścia między domenami (CDC)](modules/15-zegary-reset-cdc/README.md) | 🧩🛠️💼 | 7 | 18 h |
| 16 | [Wydajność, zasoby i pobór mocy](modules/16-wydajnosc-zasoby-moc/README.md) | 🧩🛠️💼 | 6 | 14 h |
| 17 | [Uruchamianie i debug na sprzęcie](modules/17-debug-na-sprzecie/README.md) | 🛠️💼 | 5 | 10 h |

### V. Bloki i interfejsy

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 18 | [Pamięci w FPGA](modules/18-pamieci/README.md) | 🧩🛠️💼 | 6 | 14 h |
| 19 | [Arytmetyka i liczby w sprzęcie](modules/19-arytmetyka/README.md) | 🧩🛠️💼 | 6 | 16 h |
| 20 | [Interfejsy szeregowe niskiej szybkości](modules/20-interfejsy-szeregowe/README.md) | 🛠️💼 | 6 | 16 h |
| 21 | [Magistrale i interfejsy na chipie](modules/21-magistrale-on-chip/README.md) | 🧩🛠️💼 | 6 | 16 h |
| 22 | [Wejścia-wyjścia i szybkie interfejsy](modules/22-io-i-szybkie-interfejsy/README.md) | 🛠️💼 | 6 | 14 h |
| 23 | [Pamięci zewnętrzne](modules/23-pamieci-zewnetrzne/README.md) | 🛠️💼 | 5 | 16 h |
| 24 | [Wideo i grafika](modules/24-wideo-i-grafika/README.md) | 🛠️ | 6 | 18 h |
| 25 | [Audio i Ethernet](modules/25-audio-i-ethernet/README.md) | 🛠️ | 5 | 16 h |

### VI. Systemy i zastosowania

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 26 | [Cyfrowe przetwarzanie sygnałów w FPGA](modules/26-dsp-w-fpga/README.md) | 🧩💼 | 7 | 20 h |
| 27 | [Procesory w FPGA i systemy SoC](modules/27-procesory-i-soc/README.md) | 🧩🛠️💼 | 7 | 22 h |
| 28 | [Synteza wysokiego poziomu (HLS) i akceleracja](modules/28-hls-i-akceleracja/README.md) | 🧩 | 6 | 14 h |
| 29 | [Konfiguracja, bezpieczeństwo i niezawodność](modules/29-konfiguracja-niezawodnosc/README.md) | 🛠️💼 | 5 | 12 h |

### VII. Warsztat i projekty

| # | Moduł | Oznaczenia | Tematów | Czas |
|---|-------|------------|---------|------|
| 30 | [Metodyka i warsztat inżyniera FPGA](modules/30-warsztat-inzyniera/README.md) | 💼 | 5 | 8 h |
| 31 | [Projekty końcowe na DECA](modules/31-projekty-koncowe/README.md) | 🛠️💼 | 6 | 60 h |
<!-- mapa:stop -->

## Pozostałe katalogi

| Katalog | Zawartość |
|---------|-----------|
| [plytka-deca/](plytka-deca/README.md) | Płytka Arrow DECA i układ MAX 10: zasoby, zegary, peryferia, piny, programowanie, cechy specyficzne dla MAX 10 |
| [rozmowa-kwalifikacyjna/](rozmowa-kwalifikacyjna/README.md) | Jak wygląda rekrutacja na stanowisko FPGA, zbiór pytań, zadania projektowe na tablicę, pułapki |
| [docs/STYL-KODU.md](docs/STYL-KODU.md) | Styl kodu HDL, układ katalogów modułu i zasady testbenchy |
| [tools/](tools/run_hdl_tests.py) | Skrypty: testbenche (`run_hdl_tests.py`), linki (`check_links.py`), ściągi i zbiór pytań (`zbierz.py`), strona (`build_site.py`) |

## Zasady pracy, które naprawdę działają

- **Najpierw narysuj, potem pisz.** Schemat blokowy i diagram czasowy przed pierwszą linią kodu.
- **Najpierw testbench, potem płytka.** Na sprzęcie widać mniej niż w symulacji.
- **Czytaj raporty.** Ostrzeżenia syntezy i raport czasowy mówią więcej niż dioda, która nie miga.
- **Pisz każdy przykład samodzielnie w drugim języku.** Tłumaczenie z VHDL na SystemVerilog i z powrotem najszybciej pokazuje, co jest językiem, a co sprzętem.
- **Moduł jest zaliczony**, gdy potrafisz napisać układ od zera bez notatek, zweryfikować go i uruchomić na płytce.

## Licencja

Treść własna repozytorium (notatki, przykłady, kod, zadania): **CC BY-SA 4.0**, kod HDL i skrypty dodatkowo **MIT** — szczegóły w [LICENSE.md](LICENSE.md).
Materiały zewnętrzne pozostają własnością ich autorów i są tu tylko linkowane.
