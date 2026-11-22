# FPGA — od bramki do systemu na chipie

Otwarta baza wiedzy o projektowaniu układów FPGA, prowadząca od podstaw logiki cyfrowej do **poziomu zawodowego inżyniera FPGA**: projektowania RTL, weryfikacji (SystemVerilog, UVM, cocotb, metody formalne), analizy czasowej, przejść między domenami zegarowymi, interfejsów, systemów z procesorem i przygotowania do rozmowy kwalifikacyjnej.

**Strona kursu:** [kanthakdominik.github.io/FPGA](https://kanthakdominik.github.io/FPGA/) — ta sama treść z menu, wyszukiwarką i kodem w trzech językach przełączanym zakładkami.

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
5. Przerabiaj moduły. Każdy temat ma ten sam układ (pełny opis w [docs/SZABLON-TEMATU.md](docs/SZABLON-TEMATU.md)):

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

6. Do powtórki: każdy moduł ma **ściągę** (`SCIAGA.md`), a przed rozmową kwalifikacyjną jest [zbiór pytań](rozmowa-kwalifikacyjna/README.md). Nieznane słowo sprawdzisz w [słowniczku](SLOWNICZEK.md).
7. Postęp odznaczaj w checklistach (`- [ ]` → `- [x]`) we własnym forku.

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

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 00 | [Środowisko pracy i pierwszy projekt](modules/00-srodowisko-pracy/README.md) | 🟢🛠️ | 7 | 8 h | ✅ pełny |
| 01 | [Logika cyfrowa dla projektanta FPGA](modules/01-logika-cyfrowa/README.md) | 🟢🛠️💼 | 8 | 14 h | ✅ pełny |
| 02 | [Architektura układów FPGA](modules/02-architektura-fpga/README.md) | 🟢🛠️💼 | 10 | 12 h | ✅ pełny |
| 03 | [Przepływ projektowy od RTL do bitstreamu](modules/03-przeplyw-projektowy/README.md) | 🟢🛠️💼 | 7 | 10 h | ✅ pełny |

### II. Języki opisu sprzętu i wzorce RTL

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 04 | [VHDL](modules/04-vhdl/README.md) | 🧩💼 | 9 | 24 h | ✅ pełny |
| 05 | [Verilog](modules/05-verilog/README.md) | 🧩🛠️💼 | 7 | 18 h | ✅ pełny |
| 06 | [SystemVerilog do projektowania](modules/06-systemverilog-rtl/README.md) | 🧩💼 | 7 | 16 h | ✅ pełny |
| 07 | [Kodowanie pod syntezę — wzorce RTL](modules/07-kodowanie-pod-synteze/README.md) | 🧩🛠️💼 | 9 | 20 h | ✅ pełny |
| 08 | [Automaty stanów i sterowanie](modules/08-automaty-stanow/README.md) | 🧩🛠️💼 | 6 | 14 h | ✅ pełny |

### III. Weryfikacja

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 09 | [Symulacja i testbenche](modules/09-symulacja-i-testbench/README.md) | 🔍💼 | 7 | 16 h | ✅ pełny |
| 10 | [Weryfikacja w SystemVerilogu](modules/10-weryfikacja-systemverilog/README.md) | 🔍💼 | 7 | 24 h | ✅ pełny |
| 11 | [UVM — Universal Verification Methodology](modules/11-uvm/README.md) | 🔍💼 | 8 | 24 h | ✅ pełny |
| 12 | [Weryfikacja z otwartymi narzędziami](modules/12-weryfikacja-open-source/README.md) | 🔍 | 6 | 16 h | ✅ pełny |
| 13 | [Weryfikacja formalna](modules/13-weryfikacja-formalna/README.md) | 🔍💼 | 5 | 12 h | ✅ pełny |

### IV. Czas, zegary i implementacja

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 14 | [Statyczna analiza czasowa (STA)](modules/14-analiza-czasowa/README.md) | 🛠️💼 | 6 | 16 h | ✅ pełny |
| 15 | [Zegary, reset i przejścia między domenami (CDC)](modules/15-zegary-reset-cdc/README.md) | 🧩🛠️💼 | 7 | 18 h | ✅ pełny |
| 16 | [Wydajność, zasoby i pobór mocy](modules/16-wydajnosc-zasoby-moc/README.md) | 🧩🛠️💼 | 6 | 14 h | ✅ pełny |
| 17 | [Uruchamianie i debug na sprzęcie](modules/17-debug-na-sprzecie/README.md) | 🛠️💼 | 5 | 10 h | ✅ pełny |

### V. Bloki i interfejsy

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 18 | [Pamięci w FPGA](modules/18-pamieci/README.md) | 🧩🛠️💼 | 6 | 14 h | ✅ pełny |
| 19 | [Arytmetyka i liczby w sprzęcie](modules/19-arytmetyka/README.md) | 🧩🛠️💼 | 6 | 16 h | ✅ pełny |
| 20 | [Interfejsy szeregowe niskiej szybkości](modules/20-interfejsy-szeregowe/README.md) | 🛠️💼 | 6 | 16 h | ✅ pełny |
| 21 | [Magistrale i interfejsy na chipie](modules/21-magistrale-on-chip/README.md) | 🧩🛠️💼 | 6 | 16 h | ✅ pełny |
| 22 | [Wejścia-wyjścia i szybkie interfejsy](modules/22-io-i-szybkie-interfejsy/README.md) | 🛠️💼 | 6 | 14 h | ✅ pełny |
| 23 | [Pamięci zewnętrzne](modules/23-pamieci-zewnetrzne/README.md) | 🛠️💼 | 5 | 16 h | ✅ pełny |
| 24 | [Wideo i grafika](modules/24-wideo-i-grafika/README.md) | 🛠️ | 6 | 18 h | ✅ pełny |
| 25 | [Audio i Ethernet](modules/25-audio-i-ethernet/README.md) | 🛠️ | 5 | 16 h | ✅ pełny |

### VI. Systemy i zastosowania

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 26 | [Cyfrowe przetwarzanie sygnałów w FPGA](modules/26-dsp-w-fpga/README.md) | 🧩💼 | 7 | 20 h | ✅ pełny |
| 27 | [Procesory w FPGA i systemy SoC](modules/27-procesory-i-soc/README.md) | 🧩🛠️💼 | 7 | 22 h | ✅ pełny |
| 28 | [Synteza wysokiego poziomu (HLS) i akceleracja](modules/28-hls-i-akceleracja/README.md) | 🧩 | 6 | 14 h | ✅ pełny |
| 29 | [Konfiguracja, bezpieczeństwo i niezawodność](modules/29-konfiguracja-niezawodnosc/README.md) | 🛠️💼 | 5 | 12 h | ✅ pełny |

### VII. Warsztat i projekty

| # | Moduł | Oznaczenia | Tematów | Czas | Status |
|---|-------|------------|---------|------|--------|
| 30 | [Metodyka i warsztat inżyniera FPGA](modules/30-warsztat-inzyniera/README.md) | 💼 | 5 | 8 h | 🔲 szkielet |
| 31 | [Projekty końcowe na DECA](modules/31-projekty-koncowe/README.md) | 🛠️💼 | 6 | 60 h | 🔲 szkielet |
<!-- mapa:stop -->

🔲 szkielet — tylko nagłówki · 🟡 w trakcie · ✅ pełny — notatki, kod w trzech językach z przechodzącymi testbenchami, projekt na DECA, pytania i zadania z odpowiedziami, źródła

## Pozostałe katalogi

| Katalog | Zawartość |
|---------|-----------|
| [plytka-deca/](plytka-deca/README.md) | Płytka Arrow DECA i układ MAX 10: zasoby, zegary, peryferia, piny, programowanie, cechy specyficzne dla MAX 10 |
| [rozmowa-kwalifikacyjna/](rozmowa-kwalifikacyjna/README.md) | Jak wygląda rekrutacja na stanowisko FPGA, zbiór pytań, zadania projektowe na tablicę, pułapki |
| [docs/](docs/SZABLON-TEMATU.md) | Szablon tematu i [styl kodu](docs/STYL-KODU.md) — zasady dla autorów |
| [tools/](tools/run_hdl_tests.py) | Skrypty: testbenche (`run_hdl_tests.py`), linki (`check_links.py`), ściągi i zbiór pytań (`zbierz.py`), strona (`build_site.py`) |

## Sprawdzanie materiałów

- **Testbenche** ze wszystkich modułów uruchamia [tools/run_hdl_tests.py](tools/run_hdl_tests.py): VHDL w GHDL, Verilog w Icarus Verilog, SystemVerilog w Verilatorze. Każdy testbench wypisuje `PASS` lub `FAIL`.
- **Synteza** — każdy moduł Verilog jest syntezowany w Yosysie na LUT4 ([tools/synteza_yosys.py](tools/synteza_yosys.py)): błąd syntezy zatrzymuje CI, a liczby LUT, przerzutników i zatrzasków trafiają do logu.
- **Linki** między plikami sprawdza [tools/check_links.py](tools/check_links.py).
- **Moduły nadrzędne DECA** (`deca_top.*`) są kompilowane w tych samych narzędziach razem z kodem z `hdl/` — Quartusa w CI nie ma, ale literówki i błędy typów wychodzą od razu.
- **Strona** budowana jest przez [tools/build_site.py](tools/build_site.py) i MkDocs Material w trybie `--strict` — błędny link zatrzymuje publikację.
- Wszystkie sprawdzenia wykonuje GitHub Actions przy każdym pushu ([konfiguracja](.github/workflows/checks.yml)) — wynik w zakładce *Actions*.
- Projekty na DECA nie są kompilowane w CI (Quartus jest za duży); przy problemie z kompilacją zgłoś to w Issues.

## Zasady pracy, które naprawdę działają

- **Najpierw narysuj, potem pisz.** Schemat blokowy i diagram czasowy przed pierwszą linią kodu.
- **Najpierw testbench, potem płytka.** Na sprzęcie widać mniej niż w symulacji.
- **Czytaj raporty.** Ostrzeżenia syntezy i raport czasowy mówią więcej niż dioda, która nie miga.
- **Pisz każdy przykład samodzielnie w drugim języku.** Tłumaczenie z VHDL na SystemVerilog i z powrotem najszybciej pokazuje, co jest językiem, a co sprzętem.
- **Moduł jest zaliczony**, gdy potrafisz napisać układ od zera bez notatek, zweryfikować go i uruchomić na płytce.

## Licencja

Treść własna repozytorium (notatki, przykłady, kod, zadania): **CC BY-SA 4.0**, kod HDL i skrypty dodatkowo **MIT** — szczegóły w [LICENSE.md](LICENSE.md).
Materiały zewnętrzne pozostają własnością ich autorów i są tu tylko linkowane.
