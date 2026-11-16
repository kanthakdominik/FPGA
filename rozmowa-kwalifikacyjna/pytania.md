# Pytania rekrutacyjne

[← rozmowa kwalifikacyjna](README.md)

Pytania ze wszystkich tematów, ułożone według modułów, z wzorcowymi odpowiedziami pod `<details>`. Generowane przez `tools/zbierz.py` z sekcji „Pytania rekrutacyjne” tematów — nie edytuj tego pliku ręcznie, zmieniaj pytania w tematach.

## 00 — Środowisko pracy i pierwszy projekt

### [00.01 — Czym jest FPGA i gdzie się go używa](../modules/00-srodowisko-pracy/00.01-czym-jest-fpga-i-gdzie-sie-go-uzywa.md)

1. **Czym jest FPGA i czym różni się od mikroprocesora?**

<details>
<summary>Odpowiedź</summary>

FPGA to układ z programowalnymi blokami logicznymi, połączeniami i wyprowadzeniami, którego funkcję określa plik konfiguracyjny. Mikroprocesor ma stały sprzęt i wykonuje sekwencję instrukcji z pamięci. W FPGA opisuje się sam sprzęt, który pracuje równolegle i deterministycznie — każda funkcja ma własne zasoby, nie dzieli czasu z innymi.
</details>

2. **Z jakich podstawowych zasobów składa się FPGA?**

<details>
<summary>Odpowiedź</summary>

Z bloków logicznych (tablice LUT i przerzutniki, w Alterze nazywane LE lub ALM, w AMD — slice/CLB), programowalnej sieci połączeń i bloków wejścia-wyjścia. Do tego bloki wyspecjalizowane: pamięć blokowa, bloki DSP (mnożarki), pętle PLL, a w części układów procesory i nadajniki-odbiorniki szeregowe.
</details>

3. **Dlaczego większość FPGA trzeba konfigurować po każdym włączeniu zasilania?**

<details>
<summary>Odpowiedź</summary>

Bo konfiguracja przechowywana jest w komórkach SRAM, które tracą zawartość bez zasilania. Przy starcie układ wczytuje bitstream z zewnętrznej pamięci flash albo dostaje go od procesora. Wyjątkami są układy z wbudowanym flashem (MAX 10, Lattice MachXO, Microchip PolarFire/IGLOO) i układy antifuse.
</details>

4. **Podaj trzy zastosowania, w których FPGA wygrywa z procesorem, i uzasadnij.**

<details>
<summary>Odpowiedź</summary>

Na przykład: przetwarzanie sygnałów radiowych (ogromny strumień próbek i równoległe filtry), handel wysokich częstotliwości (deterministyczne opóźnienie w nanosekundach), prototypowanie ASIC (emulacja przyszłego układu przed produkcją). Wspólny mianownik: równoległość, przewidywalny czas reakcji i własne interfejsy sprzętowe.
</details>

### [00.02 — FPGA, mikrokontroler, procesor, GPU i ASIC — kiedy co](../modules/00-srodowisko-pracy/00.02-fpga-mikrokontroler-procesor-gpu-i-asic-kiedy-co.md)

1. **Kiedy wybierzesz FPGA zamiast mikrokontrolera, a kiedy zamiast GPU?**

<details>
<summary>Odpowiedź</summary>

Zamiast mikrokontrolera — gdy przepustowość lub czas reakcji przekraczają jego możliwości albo potrzebne są nietypowe, liczne lub bardzo szybkie interfejsy. Zamiast GPU — gdy liczy się niskie, deterministyczne opóźnienie, przetwarzanie strumieniowe w czasie rzeczywistym, niski pobór mocy albo bezpośrednie podłączenie do przetworników i interfejsów sprzętowych. GPU jest lepsze przy masowych obliczeniach wsadowych.
</details>

2. **Co to jest NRE i dlaczego decyduje o wyborze między FPGA a ASIC?**

<details>
<summary>Odpowiedź</summary>

NRE (*Non-Recurring Engineering*) to jednorazowy koszt projektu: zespół, narzędzia, weryfikacja, a w ASIC także maski produkcyjne liczone w milionach dolarów. ASIC ma niski koszt jednostkowy, więc opłaca się dopiero przy dużym nakładzie, gdy NRE rozłoży się na wiele sztuk. FPGA ma niskie NRE i wyższy koszt jednostkowy — wygrywa przy małych i średnich nakładach oraz gdy funkcja może się zmieniać.
</details>

3. **Czym jest SoC FPGA i jak dzielisz w nim pracę?**

<details>
<summary>Odpowiedź</summary>

To układ z twardym procesorem (zwykle ARM) i logiką programowalną połączonymi szybkimi magistralami (np. AXI). Procesor dostaje system operacyjny, sieć, interfejs użytkownika i sterowanie wysokiego poziomu; logika programowalna — przetwarzanie strumieni danych, interfejsy czasu rzeczywistego i akceleratory. Granica przebiega tam, gdzie zadanie przestaje być rozgałęzioną logiką, a staje się regularnym przepływem danych.
</details>

### [00.03 — Instalacja: Quartus Prime Lite i Questa Starter](../modules/00-srodowisko-pracy/00.03-instalacja-quartus-prime-lite-i-questa-starter.md)

1. **Jakie znasz edycje Quartusa i kiedy potrzebujesz płatnej?**

<details>
<summary>Odpowiedź</summary>

Lite (darmowa: MAX 10, Cyclone IV, Cyclone V i inne mniejsze rodziny), Standard (płatna, starsze duże rodziny jak Arria, Stratix V) i Pro (najnowsze rodziny Agilex, Stratix 10, Cyclone 10 GX — ta ostatnia także bez licencji). Płatnej potrzebujesz przy dużych lub nowych układach albo przy funkcjach dostępnych tylko w wyższych edycjach.
</details>

2. **Masz zainstalowany Quartus, programator jest widoczny, ale `jtagconfig` nie pokazuje układu. Co sprawdzasz?**

<details>
<summary>Odpowiedź</summary>

Zasilanie płytki (dioda zasilania, zasilacz), czy kabel jest w złączu programatora, a nie innym USB, czy układ nie jest w stanie resetu albo uszkodzony łańcuch JTAG, i na końcu uprawnienia oraz `jtagd` (zabicie i ponowne uruchomienie).
</details>

### [00.04 — Instalacja: GHDL, Icarus Verilog, Verilator i OSS CAD Suite](../modules/00-srodowisko-pracy/00.04-instalacja-ghdl-icarus-verilog-verilator-i-oss.md)

1. **Czym różni się symulator zdarzeniowy (Icarus, Questa) od Verilatora?**

<details>
<summary>Odpowiedź</summary>

Symulator zdarzeniowy przetwarza zmiany sygnałów jedna po drugiej w kolejce zdarzeń i obsługuje pełną semantykę czasu, opóźnień i stanów `X`/`Z`. Verilator tłumaczy projekt na model cyklowy w C++ — jest o rząd wielkości lub więcej szybszy, ale historycznie dwustanowy i z ograniczoną obsługą konstrukcji czysto symulacyjnych. Od wersji 5 obsługuje opóźnienia i zdarzenia w testbenchach (`--timing`).
</details>

2. **Po co w projekcie FPGA otwarte symulatory, skoro jest Questa?**

<details>
<summary>Odpowiedź</summary>

Do automatycznej regresji w CI (brak licencji na serwerach, szybki start), do szybkich testów jednostkowych, lintu (Verilator) i formalnej weryfikacji (SymbiYosys). Questa zostaje do debugowania z przebiegami, pokrycia kodu i UVM.
</details>

### [00.05 — Edytor i podgląd przebiegów: VS Code, TerosHDL, GTKWave, Surfer](../modules/00-srodowisko-pracy/00.05-edytor-i-podglad-przebiegow-vs-code-teroshdl.md)

1. **Test nie przechodzi. Jak szukasz przyczyny?**

<details>
<summary>Odpowiedź</summary>

Czytam komunikat testbencha i ustalam pierwszy moment niezgodności. Zapisuję przebiegi, otwieram je na tym momencie i cofam się po sygnałach od wyjścia do wejść — do pierwszego sygnału, który ma wartość inną niż oczekiwana. Tam szukam błędu w kodzie. Jeśli to możliwe, upraszczam test do najkrótszego przypadku, który wywołuje błąd.
</details>

2. **Czym różni się VCD od FST i kiedy wybierzesz który?**

<details>
<summary>Odpowiedź</summary>

VCD to tekstowy standard IEEE, czytany przez każde narzędzie, ale duży i wolny. FST to skompresowany format GTKWave — wielokrotnie mniejszy i szybszy w przeglądaniu. Do długich symulacji i dużych projektów FST, do wymiany z innymi narzędziami albo gdy coś nie obsługuje FST — VCD.
</details>

### [00.06 — Pierwszy projekt: migająca dioda w trzech językach](../modules/00-srodowisko-pracy/00.06-pierwszy-projekt-migajaca-dioda-w-trzech.md)

1. **Ile bitów potrzebuje licznik, żeby z zegara 100 MHz zrobić impuls co 1 ms?**

<details>
<summary>Odpowiedź</summary>

1 ms przy 100 MHz to 100 000 taktów. Licznik liczy od 0 do 99 999, więc potrzeba $\lceil\log_2 100\,000\rceil = 17$ bitów ($2^{16} = 65\,536$ to za mało, $2^{17} = 131\,072$ wystarcza).
</details>

2. **Dlaczego nie użyjesz najstarszego bitu licznika jako zegara dla reszty układu?**

<details>
<summary>Odpowiedź</summary>

Bo taki „zegar” jest wyjściem zwykłej logiki: nie idzie globalną siecią zegarową, ma duży i nieprzewidywalny skew, tworzy nową domenę zegarową z problemami CDC i komplikuje analizę czasową. Poprawnie: wszystko taktujemy jednym zegarem, a licznik generuje jednotaktowy impuls *clock enable*, który zezwala wolniejszej logice na pracę.
</details>

3. **Po co synchronizator na przycisku, skoro przycisk ma przerzutnik Schmitta?**

<details>
<summary>Odpowiedź</summary>

Przerzutnik Schmitta usuwa szum i powolne zbocza na wejściu (częściowo także drgania styków), ale nie wyrównuje chwili zmiany sygnału do zegara. Zmiana tuż przy zboczu zegara może wprowadzić przerzutnik w stan metastabilny; dwa przerzutniki pod rząd dają metastabilności czas na wygaśnięcie i zapewniają, że cała logika widzi tę samą wartość.
</details>

4. **Czym różni się plik `.sof` od `.pof` w MAX 10?**

<details>
<summary>Odpowiedź</summary>

`.sof` (*SRAM Object File*) wgrywa się przez JTAG wprost do pamięci konfiguracyjnej SRAM — działa od razu, ale znika po wyłączeniu zasilania. `.pof` (*Programmer Object File*) zapisuje konfigurację do wewnętrznej pamięci flash (CFM) MAX 10, z której układ sam się konfiguruje przy każdym włączeniu.
</details>

5. **Dlaczego ścieżki do diod i od przycisku są oznaczone jako `false path`?**

<details>
<summary>Odpowiedź</summary>

Bo nie mają związku czasowego z zegarem, który dałoby się sensownie sprawdzić: przycisk zmienia się w dowolnej chwili (i przechodzi przez synchronizator), a diody są obserwowane okiem. Bez wyjątku Timing Analyzer próbowałby analizować je jak ścieżki I/O bez zdefiniowanych opóźnień wejścia i wyjścia i zgłaszałby nieograniczone ścieżki.
</details>

### [00.07 — Struktura repozytorium projektu FPGA i Git](../modules/00-srodowisko-pracy/00.07-struktura-repozytorium-projektu-fpga-i-git.md)

1. **Jakie pliki projektu Quartus lub Vivado umieścisz w systemie kontroli wersji?**

<details>
<summary>Odpowiedź</summary>

Kod HDL, testbenche, ograniczenia (`.sdc`/`.xdc`, przypisania pinów), skrypty Tcl tworzące projekt i budujące bitstream, konfiguracje rdzeni IP (`.ip`, `.qsys`, `.xci`, `.bd` albo skrypt Tcl je odtwarzający), pliki inicjalizacji pamięci i dokumentację. Bez baz danych, raporty, wygenerowanego kodu IP (jeśli da się go odtworzyć) i bitstreamów — te ostatnie jako artefakty wydań.
</details>

2. **Jak zapewnisz, że bitstream z płytki da się odtworzyć za rok?**

<details>
<summary>Odpowiedź</summary>

Tag w repozytorium dla każdej wydanej wersji, skrypt budujący projekt od zera bez ręcznych kroków w GUI, zapisana wersja narzędzia (np. w README i w skrypcie), skonfigurowane źródła rdzeni IP, a najlepiej budowanie w CI lub w kontenerze z ustaloną wersją Quartusa. Do tego zapisanie w bitstreamie identyfikatora wersji (np. rejestr z hashem commita), żeby z płytki dało się odczytać, z czego go zbudowano.
</details>

## 01 — Logika cyfrowa dla projektanta FPGA

_Pytania pojawią się razem z treścią modułu ([01-logika-cyfrowa](../modules/01-logika-cyfrowa/README.md))._

## 02 — Architektura układów FPGA

_Pytania pojawią się razem z treścią modułu ([02-architektura-fpga](../modules/02-architektura-fpga/README.md))._

## 03 — Przepływ projektowy od RTL do bitstreamu

_Pytania pojawią się razem z treścią modułu ([03-przeplyw-projektowy](../modules/03-przeplyw-projektowy/README.md))._

## 04 — VHDL

_Pytania pojawią się razem z treścią modułu ([04-vhdl](../modules/04-vhdl/README.md))._

## 05 — Verilog

_Pytania pojawią się razem z treścią modułu ([05-verilog](../modules/05-verilog/README.md))._

## 06 — SystemVerilog do projektowania

_Pytania pojawią się razem z treścią modułu ([06-systemverilog-rtl](../modules/06-systemverilog-rtl/README.md))._

## 07 — Kodowanie pod syntezę — wzorce RTL

_Pytania pojawią się razem z treścią modułu ([07-kodowanie-pod-synteze](../modules/07-kodowanie-pod-synteze/README.md))._

## 08 — Automaty stanów i sterowanie

_Pytania pojawią się razem z treścią modułu ([08-automaty-stanow](../modules/08-automaty-stanow/README.md))._

## 09 — Symulacja i testbenche

_Pytania pojawią się razem z treścią modułu ([09-symulacja-i-testbench](../modules/09-symulacja-i-testbench/README.md))._

## 10 — Weryfikacja w SystemVerilogu

_Pytania pojawią się razem z treścią modułu ([10-weryfikacja-systemverilog](../modules/10-weryfikacja-systemverilog/README.md))._

## 11 — UVM — Universal Verification Methodology

_Pytania pojawią się razem z treścią modułu ([11-uvm](../modules/11-uvm/README.md))._

## 12 — Weryfikacja z otwartymi narzędziami

_Pytania pojawią się razem z treścią modułu ([12-weryfikacja-open-source](../modules/12-weryfikacja-open-source/README.md))._

## 13 — Weryfikacja formalna

_Pytania pojawią się razem z treścią modułu ([13-weryfikacja-formalna](../modules/13-weryfikacja-formalna/README.md))._

## 14 — Statyczna analiza czasowa (STA)

_Pytania pojawią się razem z treścią modułu ([14-analiza-czasowa](../modules/14-analiza-czasowa/README.md))._

## 15 — Zegary, reset i przejścia między domenami (CDC)

_Pytania pojawią się razem z treścią modułu ([15-zegary-reset-cdc](../modules/15-zegary-reset-cdc/README.md))._

## 16 — Wydajność, zasoby i pobór mocy

_Pytania pojawią się razem z treścią modułu ([16-wydajnosc-zasoby-moc](../modules/16-wydajnosc-zasoby-moc/README.md))._

## 17 — Uruchamianie i debug na sprzęcie

_Pytania pojawią się razem z treścią modułu ([17-debug-na-sprzecie](../modules/17-debug-na-sprzecie/README.md))._

## 18 — Pamięci w FPGA

_Pytania pojawią się razem z treścią modułu ([18-pamieci](../modules/18-pamieci/README.md))._

## 19 — Arytmetyka i liczby w sprzęcie

_Pytania pojawią się razem z treścią modułu ([19-arytmetyka](../modules/19-arytmetyka/README.md))._

## 20 — Interfejsy szeregowe niskiej szybkości

_Pytania pojawią się razem z treścią modułu ([20-interfejsy-szeregowe](../modules/20-interfejsy-szeregowe/README.md))._

## 21 — Magistrale i interfejsy na chipie

_Pytania pojawią się razem z treścią modułu ([21-magistrale-on-chip](../modules/21-magistrale-on-chip/README.md))._

## 22 — Wejścia-wyjścia i szybkie interfejsy

_Pytania pojawią się razem z treścią modułu ([22-io-i-szybkie-interfejsy](../modules/22-io-i-szybkie-interfejsy/README.md))._

## 23 — Pamięci zewnętrzne

_Pytania pojawią się razem z treścią modułu ([23-pamieci-zewnetrzne](../modules/23-pamieci-zewnetrzne/README.md))._

## 24 — Wideo i grafika

_Pytania pojawią się razem z treścią modułu ([24-wideo-i-grafika](../modules/24-wideo-i-grafika/README.md))._

## 25 — Audio i Ethernet

_Pytania pojawią się razem z treścią modułu ([25-audio-i-ethernet](../modules/25-audio-i-ethernet/README.md))._

## 26 — Cyfrowe przetwarzanie sygnałów w FPGA

_Pytania pojawią się razem z treścią modułu ([26-dsp-w-fpga](../modules/26-dsp-w-fpga/README.md))._

## 27 — Procesory w FPGA i systemy SoC

_Pytania pojawią się razem z treścią modułu ([27-procesory-i-soc](../modules/27-procesory-i-soc/README.md))._

## 28 — Synteza wysokiego poziomu (HLS) i akceleracja

_Pytania pojawią się razem z treścią modułu ([28-hls-i-akceleracja](../modules/28-hls-i-akceleracja/README.md))._

## 29 — Konfiguracja, bezpieczeństwo i niezawodność

_Pytania pojawią się razem z treścią modułu ([29-konfiguracja-niezawodnosc](../modules/29-konfiguracja-niezawodnosc/README.md))._

## 30 — Metodyka i warsztat inżyniera FPGA

_Pytania pojawią się razem z treścią modułu ([30-warsztat-inzyniera](../modules/30-warsztat-inzyniera/README.md))._

## 31 — Projekty końcowe na DECA

_Pytania pojawią się razem z treścią modułu ([31-projekty-koncowe](../modules/31-projekty-koncowe/README.md))._
