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

### [01.01 — Systemy liczbowe, kody i liczby ze znakiem](../modules/01-logika-cyfrowa/01.01-systemy-liczbowe-kody-i-liczby-ze-znakiem.md)

1. **Jaki jest zakres liczby 8-bitowej w kodzie U2 i dlaczego jest niesymetryczny?**

<details>
<summary>Odpowiedź</summary>

Od −128 do +127. 8 bitów to 256 wzorów; jeden zajmuje zero, które w U2 ma tylko jedną reprezentację. Zostaje 255 wzorów na liczby niezerowe, więc jedna strona musi mieć o jedną liczbę więcej — w U2 jest to strona ujemna, bo najstarszy bit ma wagę −128.
</details>

2. **Jak wykryć przepełnienie przy dodawaniu liczb ze znakiem?**

<details>
<summary>Odpowiedź</summary>

Przepełnienie jest wtedy, gdy oba składniki mają ten sam znak, a wynik ma inny: `ovf = (a[N-1] == b[N-1]) && (s[N-1] != a[N-1])`. Równoważnie: XOR przeniesienia wchodzącego do bitu znaku i przeniesienia z niego wychodzącego. Przeniesienie z najstarszego bitu samo w sobie nie oznacza przepełnienia w U2 — to sygnał przepełnienia tylko dla liczb bez znaku.
</details>

3. **Dlaczego wskaźniki asynchronicznej kolejki FIFO przenosi się między domenami zegara w kodzie Graya?**

<details>
<summary>Odpowiedź</summary>

Bo kolejne wartości licznika Graya różnią się jednym bitem. Gdy synchronizator złapie wskaźnik w trakcie zmiany, każdy bit jest próbkowany niezależnie i może trafić na starą albo nową wartość. Przy jednym zmieniającym się bicie wynik to zawsze stara albo nowa wartość wskaźnika — oba są poprawne. W kodzie binarnym przy przejściu 0111 → 1000 zmieniają się cztery bity i można odczytać dowolną mieszankę, np. 1111.
</details>

4. **Kiedy wybierzesz kodowanie stanów 1 z n zamiast binarnego?**

<details>
<summary>Odpowiedź</summary>

W FPGA domyślnie przy małych i średnich automatach: przerzutników jest dużo, a logika następnego stanu i wyjść upraszcza się do sprawdzania pojedynczych bitów, więc układ jest szybszy. Kodowanie binarne oszczędza przerzutniki, ale wymaga dekodowania pełnego słowa stanu. Syntezatory (Quartus, Vivado) same wybierają kodowanie, jeśli automat jest napisany w rozpoznawalnym stylu.
</details>

5. **Masz liczbę 4-bitową `1011` w U2. Jak ją zapisać na 8 bitach i ile wynosi?**

<details>
<summary>Odpowiedź</summary>

Rozszerzenie znakiem: `1111_1011`. Wartość: −8 + 2 + 1 = −5. Sprawdzenie: negacja `0000_0100` + 1 = `0000_0101` = 5.
</details>

### [01.02 — Algebra Boole'a i minimalizacja — co z tego robi syntezator](../modules/01-logika-cyfrowa/01.02-algebra-boole-a-i-minimalizacja-co-z-tego-robi.md)

1. **Co jest w środku tablicy LUT i ile funkcji realizuje LUT o 4 wejściach?**

<details>
<summary>Odpowiedź</summary>

LUT to mała pamięć 16 × 1 bit (wypełniana podczas konfiguracji) i multiplekser 16:1, którego wejściami wyboru są cztery sygnały logiki. Realizuje dowolną z $2^{16} = 65\,536$ funkcji czterech zmiennych z tym samym opóźnieniem.
</details>

2. **Ile LUT4 i ile poziomów logiki zajmie 16-bitowy AND?**

<details>
<summary>Odpowiedź</summary>

Pięć LUT w dwóch poziomach: cztery LUT po 4 bity i jedna łącząca ich wyniki. Ogólnie drzewo $n$ wejść w LUT o $k$ wejściach ma $\lceil \log_k n \rceil$ poziomów.
</details>

3. **Czym jest hazard i kiedy w FPGA trzeba się nim przejmować?**

<details>
<summary>Odpowiedź</summary>

To krótki fałszywy impuls na wyjściu logiki kombinacyjnej, wynikający z różnych opóźnień ścieżek przy jednoczesnej zmianie wejść. W projekcie synchronicznym jest nieszkodliwy, bo przerzutnik próbkuje sygnał po jego ustaleniu. Szkodzi, gdy taki sygnał steruje zegarem, resetem asynchronicznym, wyjściem do układu reagującego na zbocza albo przechodzi do innej domeny zegara. Rozwiązanie: rejestr na wyjściu.
</details>

4. **Po co mapy Karnaugha, skoro syntezator minimalizuje sam?**

<details>
<summary>Odpowiedź</summary>

Do zrozumienia, jak działa sklejanie i wartości obojętne, do szybkiej analizy małych funkcji na papierze i na rozmowach kwalifikacyjnych. W pracy z FPGA ręcznej minimalizacji się nie robi — ważniejsze jest ograniczenie liczby zmiennych i poziomów logiki.
</details>

### [01.03 — Bloki kombinacyjne: multipleksery, dekodery, enkodery, komparatory](../modules/01-logika-cyfrowa/01.03-bloki-kombinacyjne-multipleksery-dekodery.md)

1. **Kiedy w procesie kombinacyjnym powstaje zatrzask i jak tego uniknąć?**

<details>
<summary>Odpowiedź</summary>

Gdy istnieje ścieżka wykonania, w której wyjście nie dostaje wartości — brak `else`, niekompletny `case` bez `default`. Wtedy sygnał musi pamiętać poprzednią wartość, czyli powstaje zatrzask. Zapobiega się przez przypisanie wartości domyślnych na początku procesu albo przez pełne `if/else` i `default` w `case`. W SystemVerilogu `always_comb` dodatkowo każe narzędziu sprawdzić, czy zatrzask nie powstał.
</details>

2. **Jak zrealizować multiplekser 32:1 dla słów 32-bitowych, żeby nie był wąskim gardłem timingu?**

<details>
<summary>Odpowiedź</summary>

Podzielić go potokowo: np. osiem multiplekserów 4:1 w pierwszym takcie i 8:1 w drugim, z rejestrem pomiędzy. Inne możliwości: wybór w kodzie 1 z n z logiką AND-OR (gdy sygnał wyboru i tak jest w tym kodzie), zastąpienie multipleksera pamięcią blokową, jeśli dane są zapisywane w różnych chwilach, albo przeniesienie wyboru wcześniej w potoku.
</details>

3. **Czym różni się enkoder od enkodera priorytetowego?**

<details>
<summary>Odpowiedź</summary>

Zwykły enkoder zakłada, że na wejściu jest dokładnie jedna jedynka, i zwraca jej numer — dla wejść z kilkoma jedynkami wynik jest bez sensu (OR numerów). Enkoder priorytetowy wybiera najważniejszy (np. najstarszy) ustawiony bit i ma wyjście `valid`, mówiące, czy jakikolwiek bit jest ustawiony. Używa się go w kontrolerach przerwań i arbitrach.
</details>

4. **Dlaczego w Verilogu nie pisze się `always @(a or b)` dla logiki kombinacyjnej?**

<details>
<summary>Odpowiedź</summary>

Bo łatwo pominąć sygnał w liście czułości. Symulator wykonuje blok tylko przy zmianie sygnałów z listy, więc przy zmianie pominiętego sygnału wyjście się nie zmieni. Syntezator listę czułości ignoruje i buduje pełną logikę. Wynik: niezgodność symulacji i sprzętu. `always @*` albo `always_comb` wyznaczają listę automatycznie.
</details>

### [01.04 — Układy arytmetyczne: sumatory, przeniesienia, mnożenie](../modules/01-logika-cyfrowa/01.04-uklady-arytmetyczne-sumatory-przeniesienia.md)

1. **Narysuj sumator pełny i podaj równania.**

<details>
<summary>Odpowiedź</summary>

Dwa półsumatory i bramka OR: pierwszy liczy $p = a \oplus b$ i $g = ab$, drugi — $s = p \oplus c_{in}$ i $p \cdot c_{in}$; $c_{out} = g + p \cdot c_{in}$. Równoważnie $c_{out}$ to funkcja większościowa $ab + ac_{in} + bc_{in}$.
</details>

2. **Dlaczego w FPGA nie stosuje się sumatora carry-lookahead, skoro ma opóźnienie logarytmiczne?**

<details>
<summary>Odpowiedź</summary>

Bo FPGA ma dedykowany łańcuch przeniesień: przeniesienie między sąsiednimi elementami logicznymi biegnie krótkim, szybkim połączeniem, kilkukrotnie szybszym niż przejście przez LUT i połączenia ogólne. Sumator CLA musiałby liczyć sygnały $g$ i $p$ w LUT i przesyłać je ogólną siecią połączeń — przy typowych szerokościach jest wolniejszy i większy. Przy bardzo szerokich sumatorach dzieli się je potokowo albo na bloki *carry-select*.
</details>

3. **Jak wykryć przepełnienie w dodawaniu liczb ze znakiem, mając dostęp do przeniesień?**

<details>
<summary>Odpowiedź</summary>

$V = c_W \oplus c_{W-1}$ — przeniesienie wychodzące z bitu znaku różni się od przeniesienia wchodzącego do niego. Bez dostępu do przeniesień: oba składniki mają ten sam znak, a wynik ma inny.
</details>

4. **Ile bloków mnożarek MAX 10 zajmie mnożenie 32 × 32 bez znaku?**

<details>
<summary>Odpowiedź</summary>

Cztery bloki 18 × 18: dzielimy każdy argument na połowy 16-bitowe i liczymy $a_H b_H$, $a_H b_L$, $a_L b_H$, $a_L b_L$, a potem sumujemy je z przesunięciami o 0, 16 i 32 bity w logice. Wynik ma 64 bity. Dla liczb ze znakiem rozkład jest podobny, ale młodsze połówki traktuje się jako liczby bez znaku.
</details>

5. **Co to jest sumator carry-save i gdzie się go używa?**

<details>
<summary>Odpowiedź</summary>

To rząd niezależnych sumatorów pełnych, który z trzech liczb robi dwie (wektor sum i wektor przeniesień) bez propagacji przeniesień — opóźnienie nie zależy od szerokości. Używa się go do sumowania wielu składników naraz (drzewa Wallace'a w mnożarkach, sumy wielu próbek), a na końcu jeden zwykły sumator łączy dwa wektory.
</details>

### [01.05 — Przerzutniki, zatrzaski i rejestry](../modules/01-logika-cyfrowa/01.05-przerzutniki-zatrzaski-i-rejestry.md)

1. **Czym różni się zatrzask od przerzutnika? Dlaczego w FPGA unika się zatrzasków?**

<details>
<summary>Odpowiedź</summary>

Zatrzask jest wrażliwy na poziom: przy aktywnym zezwoleniu wyjście podąża za wejściem, przy nieaktywnym pamięta. Przerzutnik jest wyzwalany zboczem: próbkuje wejście tylko w chwili zbocza zegara. W FPGA zatrzaski utrudniają analizę czasową (przekazywanie czasu przez otwarty zatrzask), są wrażliwe na hazardy na zezwoleniu i często nie mają dedykowanego sprzętu, więc powstaje pętla kombinacyjna. Zwykle oznaczają błąd w kodzie — niekompletny `if` lub `case`.
</details>

2. **Reset synchroniczny czy asynchroniczny — który wybierzesz i dlaczego?**

<details>
<summary>Odpowiedź</summary>

Zależy od rodziny i wymagań. Asynchroniczny działa bez zegara i nie zajmuje logiki danych (w układach Altera ma dedykowane wejście), ale jego zwolnienie trzeba zsynchronizować. Synchroniczny jest odporny na zakłócenia i łatwy w analizie, ale wymaga działającego zegara; AMD zaleca go w swoich układach. W obu przypadkach resetuję tylko logikę sterującą, a ścieżkę danych zostawiam bez resetu. Najczęstszy wzorzec: asynchroniczne ustawienie, synchroniczne zwolnienie.
</details>

3. **Co się stanie, gdy w Verilogu w bloku `always @(posedge clk)` napiszesz `b = a; c = b;`?**

<details>
<summary>Odpowiedź</summary>

Przypisania blokujące wykonują się po kolei, więc `c` dostanie nową wartość `b`, czyli `a` z tego samego taktu. Syntezator zbuduje dwa rejestry `b` i `c` zasilane z `a`, a nie rejestr przesuwny dwóch stopni. Dodatkowo inne bloki czytające `b` mogą zobaczyć starą albo nową wartość zależnie od kolejności wykonania — wyścig w symulacji. Poprawnie: `b <= a; c <= b;`.
</details>

4. **Jak spowolnić część układu, np. żeby licznik zwiększał się raz na milisekundę przy zegarze 50 MHz?**

<details>
<summary>Odpowiedź</summary>

Licznik-dzielnik generuje impuls zezwolenia trwający jeden takt co 50 000 taktów, a licznik docelowy zwiększa się tylko przy aktywnym zezwoleniu. Cały układ zostaje w jednej domenie zegara 50 MHz. Nie robi się tego przez sterowanie zegara wyjściem dzielnika — to tworzy nową domenę zegara z przesunięciem i bez ograniczeń czasowych.
</details>

5. **Co jest w środku przerzutnika D?**

<details>
<summary>Odpowiedź</summary>

Dwa zatrzaski D w układzie *master-slave*. Zatrzask nadrzędny jest przezroczysty przy niskim zegarze, podrzędny przy wysokim. Na zboczu narastającym nadrzędny się zamyka i zamraża wejście, a podrzędny się otwiera i przekazuje je na wyjście. Dlatego wyjście zmienia się tylko raz na okres.
</details>

### [01.06 — Parametry czasowe: propagacja, setup, hold, clock-to-out](../modules/01-logika-cyfrowa/01.06-parametry-czasowe-propagacja-setup-hold-clock.md)

1. **Co to jest czas setup i czas hold?**

<details>
<summary>Odpowiedź</summary>

Setup to minimalny czas, przez jaki wejście przerzutnika musi być stabilne **przed** zboczem zegara; hold — minimalny czas, przez jaki musi pozostać stabilne **po** zboczu. Naruszenie któregokolwiek może spowodować zapamiętanie złej wartości albo stan metastabilny.
</details>

2. **Jak policzyć maksymalną częstotliwość zegara dla ścieżki między dwoma rejestrami?**

<details>
<summary>Odpowiedź</summary>

$f_{max} = 1 / (t_{co} + t_{logic} + t_{route} + t_{su} - t_{skew})$, gdzie składniki są wartościami maksymalnymi dla najgorszej ścieżki w projekcie, a $t_{skew}$ to opóźnienie zegara w przerzutniku docelowym względem źródłowego. W praktyce odejmuje się jeszcze niepewność zegara. Analizator liczy to dla wszystkich ścieżek i podaje $f_{max}$ najwolniejszej.
</details>

3. **Masz naruszenie hold. Czy zmniejszenie częstotliwości zegara pomoże?**

<details>
<summary>Odpowiedź</summary>

Nie. Warunek hold porównuje dane i zegar z **tego samego** zbocza, więc okres zegara w nim nie występuje. Trzeba wydłużyć najkrótszą ścieżkę danych (narzędzie robi to automatycznie przez opóźnienia w połączeniach) albo zmniejszyć przesunięcie zegara — zwykle przez poprowadzenie go siecią globalną.
</details>

4. **Czy dodatnie przesunięcie zegara (zegar dociera później do przerzutnika docelowego) jest dobre czy złe?**

<details>
<summary>Odpowiedź</summary>

Dla setup pomaga — daje danym więcej czasu. Dla hold szkodzi — przerzutnik docelowy próbkuje później, więc nowe dane z tego samego zbocza łatwiej go „dogonią”. Dlatego przesunięcie zegara trzeba minimalizować, a nie wykorzystywać, chyba że narzędzie robi to świadomie (*useful skew*).
</details>

5. **Co to jest ścieżka nieograniczona i dlaczego jest groźna?**

<details>
<summary>Odpowiedź</summary>

To ścieżka, dla której analizator nie zna wymagań czasowych — np. wejście bez `set_input_delay` albo zegar bez `create_clock`. Nie jest sprawdzana, więc raport może nie pokazywać żadnych błędów, a ścieżka i tak może być za wolna. Każdą ścieżkę trzeba ograniczyć albo świadomie wyłączyć z analizy (`set_false_path`, `set_max_delay`) z uzasadnieniem.
</details>

### [01.07 — Metastabilność — pierwsze spotkanie](../modules/01-logika-cyfrowa/01.07-metastabilnosc-pierwsze-spotkanie.md)

1. **Co to jest metastabilność i kiedy występuje?**

<details>
<summary>Odpowiedź</summary>

To stan, w którym przerzutnik przez nieokreślony czas pozostaje między poziomem 0 a 1. Występuje, gdy wejście zmienia się w oknie setup/hold wokół zbocza zegara — w praktyce przy próbkowaniu sygnałów asynchronicznych: z zewnątrz, z innej domeny zegara, przy zwalnianiu asynchronicznego resetu. Prawdopodobieństwo, że stan trwa dłużej niż $t$, maleje wykładniczo z $t$.
</details>

2. **Jak działa synchronizator dwuprzerzutnikowy i dlaczego pomaga?**

<details>
<summary>Odpowiedź</summary>

Sygnał przechodzi przez dwa przerzutniki taktowane zegarem odbiorczym, bez logiki pomiędzy. Pierwszy może wejść w stan metastabilny, ale drugi próbkuje go dopiero po prawie całym okresie zegara. MTBF rośnie wykładniczo z tym czasem, więc z kilku godzin robi się zwykle wiele lat. Synchronizator nie usuwa metastabilności, tylko czyni ją wystarczająco mało prawdopodobną.
</details>

3. **Dlaczego nie można zsynchronizować 8-bitowej magistrali ośmioma synchronizatorami?**

<details>
<summary>Odpowiedź</summary>

Bo każdy bit może zostać złapany w innym takcie — jeden przed zmianą, inny po. Wynik może być wartością, która nigdy nie wystąpiła po stronie nadawczej. Stosuje się kod Graya (zmienia się jeden bit naraz), protokół uzgadniania z jednobitowym sygnałem gotowości albo asynchroniczną kolejkę FIFO.
</details>

4. **Jak sprawdzisz w symulacji, czy synchronizator działa?**

<details>
<summary>Odpowiedź</summary>

Symulacja RTL nie modeluje metastabilności, więc samego zjawiska nie sprawdzę. Mogę sprawdzić funkcję (opóźnienie 2–3 takty, przenoszenie zmian) i ewentualnie wstrzyknąć losowe opóźnienie o takt w modelu synchronizatora, żeby zobaczyć, czy reszta układu to toleruje. Poprawność struktury sprawdzam przeglądem kodu, narzędziem do analizy CDC i raportem metastabilności w Quartusie.
</details>

### [01.08 — Automaty skończone na papierze: Moore i Mealy](../modules/01-logika-cyfrowa/01.08-automaty-skonczone-na-papierze-moore-i-mealy.md)

1. **Czym różni się automat Moore'a od automatu Mealy'ego? Który wybierzesz?**

<details>
<summary>Odpowiedź</summary>

W automacie Moore'a wyjścia zależą tylko od stanu, w Mealy'ego — od stanu i wejść. Mealy reaguje w tym samym takcie i zwykle ma mniej stanów, ale ma ścieżkę kombinacyjną od wejścia do wyjścia (dłuższe ścieżki, hazardy). Domyślnie wybieram Moore'a albo wyjścia rejestrowane; Mealy'ego — gdy reakcja w tym samym takcie jest wymagana przez protokół.
</details>

2. **Narysuj automat wykrywający sekwencję 101 z nakładaniem.**

<details>
<summary>Odpowiedź</summary>

Mealy: trzy stany — S0 (nic), S1 (ostatni bit 1), S2 (ostatnie bity 10). S0: 1→S1, 0→S0. S1: 1→S1, 0→S2. S2: 1→S1 z wyjściem 1, 0→S0. Nakładanie zapewnia przejście z S2 przy wejściu 1 do S1 (końcowa jedynka zaczyna nowy wzorzec). Moore potrzebuje czwartego stanu S3 z wyjściem 1, z którego 1→S1, 0→S2.
</details>

3. **Jakie kodowanie stanów wybierzesz w FPGA i dlaczego?**

<details>
<summary>Odpowiedź</summary>

Zwykle 1 z n: FPGA ma dużo przerzutników, a każdy bit stanu odpowiada jednemu stanowi, więc logika następnego stanu i wyjść jest płytka i szybka. Binarne przy bardzo dużych automatach albo gdy brakuje rejestrów. W praktyce piszę typ wyliczeniowy i pozwalam syntezatorowi wybrać, chyba że wymagania (np. niezawodność, wyjścia prosto z bitów stanu) mówią inaczej.
</details>

4. **Co się stanie, gdy automat w kodowaniu 1 z n wejdzie w wzór z dwiema jedynkami?**

<details>
<summary>Odpowiedź</summary>

Zachowanie jest nieokreślone — logika następnego stanu zakłada dokładnie jedną jedynkę. Automat może się „zawiesić” albo krążyć między stanami niedozwolonymi. Zabezpieczeniem jest automat bezpieczny: syntezator dodaje logikę wykrywającą stan niedozwolony i wracającą do stanu znanego (w Quartusie opcja *Safe State Machine*). Sama gałąź `default` w kodzie tego nie gwarantuje.
</details>

## 02 — Architektura układów FPGA

### [02.01 — Od PAL i CPLD do FPGA — ewolucja układów programowalnych](../modules/02-architektura-fpga/02.01-od-pal-i-cpld-do-fpga-ewolucja-ukladow.md)

1. **Czym różni się CPLD od FPGA?**

<details>
<summary>Odpowiedź</summary>

CPLD zbudowany jest z kilku bloków typu PAL (suma iloczynów i przerzutnik w makrokomórce) połączonych centralną macierzą — ma mało logiki, przewidywalne opóźnienia i nieulotną konfigurację. FPGA to tablica bloków z LUT i przerzutnikami połączonych hierarchiczną siecią; ma dużo więcej logiki, bloki wyspecjalizowane (pamięci, DSP, PLL), a opóźnienia zależą od rozmieszczenia. Większość FPGA konfiguruje się do SRAM i potrzebuje pamięci zewnętrznej; wyjątki to układy z flash (np. MAX 10) i antifuse.
</details>

2. **Dlaczego MAX 10 bywa używany tam, gdzie kiedyś stosowano CPLD?**

<details>
<summary>Odpowiedź</summary>

Bo konfiguruje się sam z wewnętrznej pamięci flash w kilka milisekund po włączeniu, nie potrzebuje zewnętrznego układu konfiguracyjnego, a wersje z jednym zasilaniem upraszczają płytkę. Daje przy tym zasoby FPGA: dużo LUT, pamięć, mnożarki, PLL i ADC. Dlatego nadaje się do sterowania zasilaniem, logiki „klejącej” i zarządzania systemem, gdzie wcześniej był CPLD.
</details>

3. **Gdzie stosuje się FPGA antifuse i dlaczego?**

<details>
<summary>Odpowiedź</summary>

W lotnictwie, kosmosie i zastosowaniach wojskowych. Połączenie antifuse jest trwałe i nie ma komórek pamięci konfiguracji, które promieniowanie mogłoby przestawić, więc układ jest odporny na błędy konfiguracji (SEU). Wada: programuje się go tylko raz.
</details>

### [02.02 — LUT, przerzutnik i blok logiczny: LE, ALM, CLB, slice](../modules/02-architektura-fpga/02.02-lut-przerzutnik-i-blok-logiczny-le-alm-clb-slice.md)

1. **Co jest w elemencie logicznym MAX 10 (albo w slice AMD)?**

<details>
<summary>Odpowiedź</summary>

LE MAX 10: LUT o 4 wejściach, jeden rejestr z zezwoleniem i resetami, logika łańcucha przeniesień i łańcucha rejestrów, multipleksery wyboru wyjścia. Pracuje w trybie normalnym (LUT4) albo arytmetycznym (dwie LUT3 i przeniesienie). 16 LE tworzy LAB ze wspólnymi sygnałami sterującymi. Slice AMD serii 7: 4 LUT6, 8 rejestrów, łańcuch przeniesień CARRY4 i multipleksery szerokich funkcji; w SLICEM LUT mogą być pamięcią lub rejestrem przesuwnym.
</details>

2. **Co to jest zestaw sygnałów sterujących i dlaczego ma znaczenie?**

<details>
<summary>Odpowiedź</summary>

To unikalna kombinacja zegara, zezwolenia i resetów rejestru. Rejestry w jednym bloku logicznym (LAB, slice) dzielą te sygnały, więc rejestry z różnymi zestawami nie mogą być w tym samym bloku. Dużo różnych zestawów oznacza gorsze upakowanie, więcej zajętych bloków i trudniejsze rozmieszczenie — czasem projekt nie mieści się, choć LUT jest dość.
</details>

3. **Dlaczego projekt na LUT6 ma zwykle mniej poziomów logiki niż na LUT4?**

<details>
<summary>Odpowiedź</summary>

Bo jedna LUT6 realizuje dowolną funkcję 6 zmiennych, a w LUT4 taka funkcja wymaga kilku LUT w dwóch poziomach. Drzewo dla $n$ wejść ma $\lceil \log_k n \rceil$ poziomów — dla $k = 6$ rośnie wolniej niż dla $k = 4$. Mniej poziomów to krótsza ścieżka krytyczna i wyższa częstotliwość.
</details>

### [02.03 — Łańcuchy przeniesień i logika arytmetyczna](../modules/02-architektura-fpga/02.03-lancuchy-przeniesien-i-logika-arytmetyczna.md)

1. **Jak FPGA realizuje sumator i dlaczego jest szybki?**

<details>
<summary>Odpowiedź</summary>

Na dedykowanym łańcuchu przeniesień: każdy element logiczny liczy jeden (w ALM — dwa, w CARRY4 — cztery) bity sumy, a przeniesienie biegnie do następnego elementu krótkim, stałym połączeniem bez programowalnych przełączników. Jest wielokrotnie szybsze niż przejście przez LUT i zwykłe połączenia, więc nawet sumator ripple-carry na kilkadziesiąt bitów mieści się w typowych zegarach.
</details>

2. **64-bitowy licznik nie spełnia wymagań czasowych. Co zrobisz?**

<details>
<summary>Odpowiedź</summary>

Podzielę go na segmenty, np. dwa 32-bitowe, z rejestrowanym sygnałem przeniesienia z niższego segmentu jako zezwoleniem dla wyższego — wyższy segment zwiększa się o takt później, co trzeba uwzględnić przy odczycie (albo odczytywać z korektą). Inne opcje: sprawdzić, czy naprawdę potrzeba 64 bitów, dodać potokowanie odczytu albo użyć licznika z prescalerem.
</details>

### [02.04 — Sieć połączeń i dlaczego trasowanie kosztuje czas](../modules/02-architektura-fpga/02.04-siec-polaczen-i-dlaczego-trasowanie-kosztuje.md)

1. **Dlaczego opóźnienie połączeń w FPGA jest tak duże w porównaniu z ASIC?**

<details>
<summary>Odpowiedź</summary>

Bo każde połączenie przechodzi przez programowalne przełączniki (multipleksery sterowane komórkami konfiguracji) i przez segmenty przewodów o stałych długościach, a nie przez przewód zaprojektowany dokładnie dla tej ścieżki. Przełączniki dodają opóźnienie i pojemność, a trasa rzadko jest najkrótsza możliwa. Dlatego w FPGA połączenia to zwykle połowa lub więcej opóźnienia ścieżki.
</details>

2. **Sygnał zezwolenia steruje 5000 rejestrów i jest na ścieżce krytycznej. Jak to poprawisz?**

<details>
<summary>Odpowiedź</summary>

Powielę rejestr źródłowy, tak żeby każda kopia sterowała mniejszą grupą (ręcznie albo atrybutem maksymalnego rozgałęzienia), albo rozprowadzę sygnał potokowo w drzewie rejestrów, kompensując opóźnienie w reszcie toru. Jeśli sygnał jest wolnozmienny, może iść siecią globalną. Sprawdzę też, czy wszystkie rejestry naprawdę potrzebują zezwolenia.
</details>

3. **Dlaczego przy wykorzystaniu układu powyżej 80–90% trudno zamknąć timing?**

<details>
<summary>Odpowiedź</summary>

Bo fitter ma mało swobody: nie może umieścić logiki blisko jej źródeł i odbiorników, a kanały połączeń są zatłoczone, więc sygnały idą okrężnymi trasami. Rosną opóźnienia połączeń i czas kompilacji. Wyjście: mniejszy projekt, większy układ albo planowanie rozmieszczenia.
</details>

### [02.05 — Bloki pamięci i pamięć rozproszona](../modules/02-architektura-fpga/02.05-bloki-pamieci-i-pamiec-rozproszona.md)

1. **Dlaczego pamięć z odczytem asynchronicznym nie trafi do bloku RAM?**

<details>
<summary>Odpowiedź</summary>

Bo bloki pamięci w FPGA mają rejestr adresu (i opcjonalnie danych) — odczyt jest synchroniczny, wynik pojawia się po zboczu zegara. Kod opisujący odczyt kombinacyjny z adresu nie pasuje do tego sprzętu, więc narzędzie buduje pamięć z rejestrów i multiplekserów albo (w rodzinach, które ją mają) z pamięci rozproszonej.
</details>

2. **Czym różni się pamięć blokowa od rozproszonej?**

<details>
<summary>Odpowiedź</summary>

Pamięć blokowa to dedykowane bloki SRAM o pojemności kilku–kilkudziesięciu Kb z odczytem synchronicznym i dwoma portami. Pamięć rozproszona to LUT w trybie pamięci (np. SLICEM w AMD, MLAB w nowszych układach Altera) — mała pojemność, odczyt asynchroniczny, rozmieszczona wśród logiki. Rozproszona jest dobra do małych pamięci i rejestrów przesuwnych, blokowa — do większych buforów. MAX 10 ma tylko pamięć blokową.
</details>

3. **Jak zrealizować pamięć 1024 × 32 bity w MAX 10 i ile bloków zajmie?**

<details>
<summary>Odpowiedź</summary>

W trybie jedno- lub prosty dwuportowym M9K mieści 256 × 32 (lub 256 × 36), więc 1024 słowa potrzebują 4 bloków — narzędzie połączy je z dekodowaniem adresu i multiplekserem wyjścia. Alternatywnie 1024 × 8 na blok i 4 bloki obok siebie (każdy po 8 bitów słowa) — tak zwykle robi Quartus, bo nie potrzeba wtedy multipleksera.
</details>

### [02.06 — Bloki DSP i mnożarki sprzętowe](../modules/02-architektura-fpga/02.06-bloki-dsp-i-mnozarki-sprzetowe.md)

1. **Ile bloków mnożarek MAX 10 zajmie mnożenie 24 × 24 i jak narzędzie je zrealizuje?**

<details>
<summary>Odpowiedź</summary>

Cztery bloki 18 × 18 (lub mniej, jeśli narzędzie użyje trybu 9 × 9 dla części iloczynów). Argumenty dzieli się na część starszą i młodszą, liczy cztery iloczyny częściowe i sumuje je z przesunięciami w logice (LE). Wynik ma 48 bitów.
</details>

2. **Co zawiera blok DSP48 i dlaczego nadaje się do filtrów FIR?**

<details>
<summary>Odpowiedź</summary>

Sumator wstępny (25 bitów), mnożarkę 25 × 18, ALU/akumulator 48 bitów, rejestry na każdym etapie i połączenia kaskadowe do sąsiednich bloków. Krok filtru FIR to mnożenie próbki (lub sumy dwóch próbek przy filtrze symetrycznym — stąd sumator wstępny) przez współczynnik i dodanie do sumy częściowej — dokładnie to, co blok robi w jednym takcie, a kaskada przenosi sumę do następnego bloku bez użycia logiki.
</details>

3. **Kiedy lepiej zrealizować mnożenie w logice niż w bloku DSP?**

<details>
<summary>Odpowiedź</summary>

Gdy mnożenie jest bardzo wąskie (kilka bitów), gdy mnożymy przez stałą z małą liczbą jedynek (przesunięcia i sumy), albo gdy w układzie brakuje bloków DSP. W pozostałych przypadkach blok jest mniejszy, szybszy i zużywa mniej energii.
</details>

### [02.07 — Zegary: sieci globalne, PLL i MMCM](../modules/02-architektura-fpga/02.07-zegary-sieci-globalne-pll-i-mmcm.md)

1. **Po co FPGA ma osobne sieci zegarowe?**

<details>
<summary>Odpowiedź</summary>

Żeby zegar docierał do wszystkich przerzutników prawie w tej samej chwili (małe przesunięcie) i z małym opóźnieniem. Sieci globalne to zrównoważone drzewa z mocnymi buforami, osobne od zwykłych połączeń. Zegar prowadzony zwykłymi połączeniami miałby duże i zmienne przesunięcie, co psuje zarówno setup, jak i hold.
</details>

2. **Jak z zegara 50 MHz otrzymać 74,25 MHz w PLL?**

<details>
<summary>Odpowiedź</summary>

$74{,}25 / 50 = 1{,}485 = 297/200$, więc szukam $M/(N \cdot C) = 297/200$ przy VCO w dozwolonym zakresie. Przykład: $N = 20$, $M = 297$ → VCO $= 50 \cdot 297 / 20 = 742{,}5$ MHz, $C = 10$ → 74,25 MHz. Trzeba sprawdzić, czy VCO i wartości liczników mieszczą się w zakresach z karty katalogowej; jeśli nie, szuka się innej kombinacji albo akceptuje przybliżenie. W praktyce wartości dobiera kreator IP, a projektant sprawdza dokładność wyniku.
</details>

3. **Czym różni się MMCM od PLL w układach AMD?**

<details>
<summary>Odpowiedź</summary>

Oba syntetyzują częstotliwości i przesuwają fazę. MMCM jest bardziej rozbudowany: ma dzielnik ułamkowy, precyzyjne dynamiczne przesuwanie fazy i więcej wyjść; PLL jest prostszy i zużywa mniej energii. W serii 7 każdy CMT ma jeden MMCM i jeden PLL.
</details>

4. **Dlaczego nie powinno się dzielić zegara licznikiem i używać wyniku jako zegara?**

<details>
<summary>Odpowiedź</summary>

Bo wyjście rejestru idzie zwykłymi połączeniami do sieci zegarowej: zegar jest opóźniony i przesunięty względem źródłowego, tworzy nową domenę z ryzykiem naruszeń hold na przejściach i wymaga ręcznych ograniczeń w SDC. Lepiej użyć zezwolenia zegara (impuls co N taktów) albo wyjścia PLL.
</details>

### [02.08 — Bloki wejścia-wyjścia i banki I/O](../modules/02-architektura-fpga/02.08-bloki-wejscia-wyjscia-i-banki-i-o.md)

1. **Co to jest bank I/O i jakie ograniczenia z niego wynikają?**

<details>
<summary>Odpowiedź</summary>

Grupa pinów ze wspólnym zasilaniem wyjść VCCIO (i ewentualnie wspólnym VREF). Wszystkie wyjścia w banku muszą używać standardów o tym samym napięciu, standardy z napięciem odniesienia wymagają pinu VREF, a niektóre funkcje (prawdziwe nadajniki LVDS, interfejsy pamięci) są dostępne tylko w wybranych bankach. Podział peryferiów między banki to decyzja przy projektowaniu płytki.
</details>

2. **Po co umieszczać rejestry w blokach IOE?**

<details>
<summary>Odpowiedź</summary>

Rejestr w IOE ma najkrótszą możliwą ścieżkę do pinu, więc czasy setup/hold na wejściu i clock-to-out na wyjściu są małe i stałe — niezależne od tego, gdzie fitter umieścił resztę logiki. To podstawa dla interfejsów synchronicznych, w których zewnętrzny układ ma określone wymagania czasowe.
</details>

3. **Czym jest terminacja na chipie i kiedy jest potrzebna?**

<details>
<summary>Odpowiedź</summary>

To programowalne rezystory w buforze I/O (szeregowe na wyjściu lub równoległe na wejściu), które dopasowują impedancję do linii na płytce. Potrzebna przy szybkich sygnałach, gdy linia jest na tyle długa, że odbicia psują sygnał — typowo pamięci DDR i szybkie interfejsy. Zastępuje rezystory na płytce, oszczędzając miejsce.
</details>

### [02.09 — Konfiguracja: SRAM, flash, antifuse — MAX 10 jako FPGA z wbudowaną pamięcią flash](../modules/02-architektura-fpga/02.09-konfiguracja-sram-flash-antifuse-max-10-jako.md)

1. **Jaka jest różnica między FPGA konfigurowanym z SRAM a z flash?**

<details>
<summary>Odpowiedź</summary>

W FPGA SRAM konfiguracja jest w ulotnych komórkach SRAM i po każdym włączeniu zasilania musi zostać wczytana z zewnętrznej pamięci — start trwa dziesiątki–setki milisekund, a komórki są podatne na błędy SEU. W FPGA flash (np. PolarFire) konfiguracja jest w nieulotnych komórkach flash sterujących strukturą — układ działa od razu i jest odporny na SEU w konfiguracji. MAX 10 to wariant pośredni: ma flash w układzie, ale logika pracuje z SRAM, do której konfiguracja jest kopiowana po włączeniu.
</details>

2. **Do czego służy podwójny obraz konfiguracji?**

<details>
<summary>Odpowiedź</summary>

Do bezpiecznej aktualizacji w terenie: jeden obraz jest „zapasowy” (fabryczny), drugi — aktualizowany. Jeśli zapis nowego obrazu się nie powiedzie albo nowy obraz nie działa, układ może wrócić do obrazu zapasowego. W MAX 10 obrazy wybiera pin `CONFIG_SEL` albo logika przez IP *Dual Configuration*.
</details>

3. **Dlaczego na płytce z MAX 10 często nie ma zewnętrznej pamięci konfiguracji?**

<details>
<summary>Odpowiedź</summary>

Bo konfiguracja jest przechowywana w wewnętrznej pamięci CFM, a układ sam kopiuje ją do CRAM po włączeniu zasilania. Pamięć zewnętrzna jest potrzebna tylko wtedy, gdy projekt potrzebuje więcej pamięci nieulotnej, niż daje UFM.
</details>

### [02.10 — Przegląd rynku: AMD, Altera, Lattice, Microchip, Gowin, Efinix](../modules/02-architektura-fpga/02.10-przeglad-rynku-amd-altera-lattice-microchip.md)

1. **Z jakimi rodzinami FPGA pracowałeś i czym się różnią?**

<details>
<summary>Odpowiedź</summary>

Przykładowa odpowiedź po tej bazie: MAX 10 (Altera) — mały układ z LUT4, wbudowaną flash konfiguracji, ADC i mnożarkami 18 × 18, narzędzie Quartus Prime Lite. Znam różnice względem AMD serii 7: LUT6 i slice'y z 8 rejestrami, DSP48 z akumulatorem, BRAM 36 Kb, pamięć rozproszona w SLICEM, konfiguracja z zewnętrznej flash, Vivado i ograniczenia XDC. Warto mówić konkretnie o zasobach i narzędziach, a nie tylko o nazwach.
</details>

2. **Jak dobrałbyś układ do nowego projektu?**

<details>
<summary>Odpowiedź</summary>

Najpierw wymagania: ilość logiki, pamięci i DSP z zapasem, interfejsy (DDR, PCIe, szybkie łącza), czy potrzebny procesor, wymagania startu, poboru mocy, temperatury i norm. Potem koszt układu i narzędzi, dostępność i długość produkcji, doświadczenie zespołu i istniejący kod. Dla kilku kandydatów robię szybką syntezę kluczowych bloków, żeby sprawdzić zasoby i częstotliwość.
</details>

3. **Kiedy wybierzesz FPGA z rodziny Microchip PolarFire zamiast układu SRAM?**

<details>
<summary>Odpowiedź</summary>

Gdy ważna jest odporność konfiguracji na promieniowanie (komórki flash nie zmieniają stanu od cząstek tak jak SRAM), natychmiastowy start po włączeniu, niski pobór mocy statycznej albo bezpieczeństwo konfiguracji — np. w lotnictwie, kosmosie, przemyśle i urządzeniach medycznych.
</details>

## 03 — Przepływ projektowy od RTL do bitstreamu

### [03.01 — Etapy: opracowanie, synteza, mapowanie, rozmieszczanie, trasowanie, bitstream](../modules/03-przeplyw-projektowy/03.01-etapy-opracowanie-synteza-mapowanie.md)

1. **Opisz przepływ projektowy od RTL do bitstreamu.**

<details>
<summary>Odpowiedź</summary>

Analiza i opracowanie kodu (sprawdzenie składni, ustalenie parametrów i hierarchii), synteza do sieci elementów ogólnych, mapowanie technologiczne na zasoby układu (LUT, rejestry, pamięci, DSP), rozmieszczanie i trasowanie z uwzględnieniem ograniczeń pinów i czasów, statyczna analiza czasowa sprawdzająca setup i hold na wszystkich ścieżkach, generowanie pliku konfiguracyjnego. Po drodze czytam raporty: ostrzeżenia syntezy, zużycie zasobów, wynik analizy czasowej i ścieżki nieograniczone.
</details>

2. **Dlaczego dwie kompilacje prawie tego samego projektu mogą dać różne wyniki czasowe?**

<details>
<summary>Odpowiedź</summary>

Bo rozmieszczanie jest heurystyczne i zależy od ziarna losowości oraz od całej sieci — mała zmiana w jednym miejscu zmienia punkt startowy algorytmu i rozmieszczenie wszystkiego. Różnice kilku procent w $f_{max}$ są normalne. Projekt z małym zapasem czasowym trzeba poprawić w kodzie lub ograniczeniach, a nie liczyć na szczęśliwe ziarno.
</details>

### [03.02 — Synteza: co robi syntezator i jak czytać jego raport](../modules/03-przeplyw-projektowy/03.02-synteza-co-robi-syntezator-i-jak-czytac-jego.md)

1. **Dlaczego syntezator usunął część mojej logiki i jak temu zapobiec?**

<details>
<summary>Odpowiedź</summary>

Bo nie wpływała na żadne wyjście projektu albo miała stałą wartość — syntezator zachowuje tylko to, co widać na pinach. Najpierw sprawdzam, czy to nie błąd (niepodłączone wyjście, warunek, który nigdy nie jest spełniony) w raporcie *Registers Removed During Synthesis*. Jeśli logika ma zostać celowo (np. do debugowania), wyprowadzam ją albo używam atrybutów `keep`/`preserve`/`noprune` (w Vivado `KEEP`, `DONT_TOUCH`).
</details>

2. **Co to jest współdzielenie zasobów w syntezie?**

<details>
<summary>Odpowiedź</summary>

Gdy dwa operatory (np. sumatory, mnożarki) nigdy nie są potrzebne w tym samym czasie, bo ich wyniki wybiera multiplekser, syntezator może zastąpić je jednym operatorem i przenieść multiplekser na jego wejścia. Oszczędza to zasoby kosztem multipleksera na ścieżce danych. Nie każde narzędzie robi to automatycznie, więc przy oszczędzaniu zasobów lepiej opisać to wprost.
</details>

3. **Czym różni się RTL Viewer od Technology Map Viewer?**

<details>
<summary>Odpowiedź</summary>

RTL Viewer pokazuje schemat po opracowaniu — ogólne bloki: rejestry, multipleksery, operatory, jak je opisał kod. Technology Map Viewer pokazuje wynik mapowania na zasoby układu: LE (LUT i rejestry), M9K, mnożarki, IOE. Pierwszy służy do sprawdzenia, czy kod opisuje zamierzoną strukturę, drugi — co naprawdę jest w układzie.
</details>

### [03.03 — Ograniczenia: piny, standardy I/O i zegary (QSF, SDC, XDC, PCF)](../modules/03-przeplyw-projektowy/03.03-ograniczenia-piny-standardy-i-o-i-zegary-qsf.md)

1. **Jakie ograniczenia czasowe musi mieć każdy projekt?**

<details>
<summary>Odpowiedź</summary>

Definicję każdego zegara wejściowego (`create_clock`) i zegarów pochodnych (PLL — `derive_pll_clocks` lub `create_generated_clock`), niepewność zegarów, opóźnienia wejść i wyjść względem zegara (`set_input_delay`, `set_output_delay`) albo uzasadnione wyłączenia ścieżek asynchronicznych, a dla wielu zegarów — relacje między nimi (`set_clock_groups` dla asynchronicznych). Cel: raport ścieżek nieograniczonych jest pusty.
</details>

2. **Czym różni się `set_false_path` od `set_clock_groups -asynchronous`?**

<details>
<summary>Odpowiedź</summary>

`set_false_path` wyłącza z analizy konkretne ścieżki wskazane przez `-from`/`-to`/`-through`. `set_clock_groups -asynchronous` deklaruje, że wszystkie ścieżki między wskazanymi grupami zegarów są asynchroniczne — w obie strony — i wyłącza je wszystkie naraz. Drugie jest wygodniejsze przy niezależnych zegarach, ale obie konstrukcje wymagają poprawnej synchronizacji w kodzie, bo narzędzie przestaje ją sprawdzać.
</details>

3. **Dlaczego składnia ograniczeń czasowych jest prawie taka sama w Quartusie i Vivado?**

<details>
<summary>Odpowiedź</summary>

Bo oba narzędzia używają formatu SDC, który wywodzi się z narzędzi ASIC (Synopsys) i jest de facto standardem. Różnią się szczegóły: polecenia dodatkowe (`derive_pll_clocks` w Quartusie, automatyczne zegary MMCM w Vivado) i sposób przypisywania pinów (QSF vs właściwości w XDC).
</details>

### [03.04 — Raporty: zasoby, czasy i ostrzeżenia, których nie wolno ignorować](../modules/03-przeplyw-projektowy/03.04-raporty-zasoby-czasy-i-ostrzezenia-ktorych-nie.md)

1. **Na jakie ostrzeżenia syntezy zwracasz uwagę w pierwszej kolejności?**

<details>
<summary>Odpowiedź</summary>

Wnioskowanie zatrzasków, obcięcie szerokości, wielokrotne sterowanie sygnału, pętle kombinacyjne, zegary z logiki lub rejestrów, wejścia bez odbiorców i wyjścia o stałej wartości, usunięte rejestry. Każde z nich może oznaczać, że sprzęt zachowa się inaczej niż symulacja. Potem raport czasowy: zapas setup i hold we wszystkich modelach i pusta lista ścieżek nieograniczonych.
</details>

2. **Projekt ma ujemny zapas hold w modelu Fast 1200mV 0C. Co to oznacza i co zrobisz?**

<details>
<summary>Odpowiedź</summary>

Na którejś ścieżce dane dochodzą do przerzutnika za szybko w warunkach najszybszych (niska temperatura) — układ może zawodzić niezależnie od częstotliwości. Sprawdzam, która to ścieżka: najczęściej przejście między domenami zegara bez poprawnych ograniczeń, zegar prowadzony logiką albo wejście z pinu z błędnym `set_input_delay -min`. Fitter zwykle naprawia hold sam; jeśli nie potrafi, przyczyna jest w strukturze zegarów lub ograniczeniach.
</details>

### [03.05 — Praca skryptowa: Tcl, tryb wsadowy i Makefile](../modules/03-przeplyw-projektowy/03.05-praca-skryptowa-tcl-tryb-wsadowy-i-makefile.md)

1. **Dlaczego projekty FPGA buduje się skryptami, a nie z GUI?**

<details>
<summary>Odpowiedź</summary>

Dla odtwarzalności i automatyzacji: skrypt w repozytorium daje ten sam wynik u każdego członka zespołu i w CI, ustawienia są widoczne w historii zmian, a kompilację można uruchomić na serwerze bez ekranu, z automatycznym sprawdzeniem raportów. GUI służy do analizy (przeglądanie raportów, schematów, ścieżek), nie do definiowania projektu.
</details>

2. **Jak w skrypcie sprawdzisz, czy projekt spełnia wymagania czasowe?**

<details>
<summary>Odpowiedź</summary>

Uruchamiam `quartus_sta -t` ze skryptem, który otwiera projekt, tworzy sieć czasową, wczytuje SDC i dla każdego modelu pracy pobiera najgorszy zapas setup i hold (np. `report_timing -npaths 1` zwraca liczbę ścieżek i najgorszy zapas). Przy ujemnym zapasie skrypt kończy się kodem błędu, co zatrzymuje CI. W Vivado podobnie: `report_timing_summary` i odczyt WNS/WHS.
</details>

### [03.06 — Otwarty przepływ: Yosys, nextpnr i narzędzia konfiguracyjne](../modules/03-przeplyw-projektowy/03.06-otwarty-przeplyw-yosys-nextpnr-i-narzedzia.md)

1. **Do czego przydaje się Yosys, gdy projekt docelowo jest w Quartusie lub Vivado?**

<details>
<summary>Odpowiedź</summary>

Do szybkiego sprawdzenia w CI, czy kod jest syntezowalny i nie ma problemów strukturalnych (wielokrotne sterowanie, niepodłączone sygnały, zatrzaski), do zgrubnego porównania zasobów dwóch wersji kodu i do weryfikacji formalnej (SymbiYosys — [moduł 13](../modules/13-weryfikacja-formalna/README.md)). Działa w sekundach i nie wymaga licencji ani wielkiej instalacji.
</details>

2. **Jakie są ograniczenia otwartych narzędzi FPGA?**

<details>
<summary>Odpowiedź</summary>

Obsługują ograniczoną liczbę rodzin (głównie Lattice iCE40 i ECP5, Gowin, GateMate), mają niepełne wsparcie SystemVerilog i VHDL (przez dodatki), brak im kreatorów IP i twardych bloków wysokiej klasy (PCIe, szybkie nadajniki), a wyniki dla dużych projektów bywają gorsze niż w narzędziach producentów. Za to są szybkie, skryptowalne i otwarte.
</details>

### [03.07 — Programowanie układu: JTAG, pliki .sof i .pof, pamięć konfiguracyjna](../modules/03-przeplyw-projektowy/03.07-programowanie-ukladu-jtag-pliki-sof-i-pof.md)

1. **Jak działa JTAG i do czego służy w projektach FPGA?**

<details>
<summary>Odpowiedź</summary>

To szeregowy interfejs testowy (IEEE 1149.1) z sygnałami TCK, TMS, TDI, TDO i automatem TAP w każdym układzie; układy łączy się w łańcuch. W FPGA służy do konfiguracji (wgrywanie bitstreamu do SRAM), programowania pamięci flash, odczytu identyfikatora, testów połączeń na płytce (boundary scan) i debugowania w działającym układzie (analizatory logiczne wbudowane w FPGA, JTAG UART, dostęp do magistral).
</details>

2. **Jaka jest różnica między plikami `.sof` i `.pof`?**

<details>
<summary>Odpowiedź</summary>

`.sof` zawiera konfigurację wgrywaną przez JTAG bezpośrednio do pamięci konfiguracyjnej SRAM — działa od razu, ale znika po wyłączeniu zasilania. `.pof` zawiera dane do zaprogramowania pamięci nieulotnej (w MAX 10 — wewnętrznej CFM i UFM, w innych rodzinach — układu konfiguracyjnego), z której układ konfiguruje się po każdym włączeniu.
</details>

## 04 — VHDL

### [04.01 — Struktura projektu: biblioteki, entity i architecture](../modules/04-vhdl/04.01-struktura-projektu-biblioteki-entity-i.md)

1. **Czym różni się entity od architecture i po co jednej entity kilka architektur?**

<details>
<summary>Odpowiedź</summary>

Entity opisuje interfejs — nazwę, parametry i porty; architecture — implementację. Kilka architektur pozwala mieć dla tego samego interfejsu np. wersję behawioralną do szybkiej symulacji i strukturalną do syntezy, albo warianty o różnej wydajności. Wybór robi się przy instancji (`entity work.x(arch)`) albo konfiguracją.
</details>

2. **Dlaczego nie powinno się używać `std_logic_unsigned`?**

<details>
<summary>Odpowiedź</summary>

To niestandardowy pakiet (Synopsys), który definiuje arytmetykę bezpośrednio na `std_logic_vector`, traktując go jako liczbę bez znaku. Łamie to silne typowanie (nie wiadomo, czy wektor jest liczbą ze znakiem), różne narzędzia mają różne wersje, a w połączeniu z `numeric_std` powstają niejednoznaczności. Standardem jest `ieee.numeric_std` z typami `unsigned` i `signed`.
</details>

3. **Jak w VHDL wygląda odpowiednik parametru modułu Verilog?**

<details>
<summary>Odpowiedź</summary>

`generic` w entity, np. `generic (W : positive := 8);`, ustawiany przy instancji przez `generic map (W => 16)`. Generic może mieć dowolny typ (liczba, boolean, string, w VHDL-2008 także typ i funkcja) i może określać typy portów.
</details>

### [04.02 — Typy: std_logic, wektory, numeric_std, integer, typy wyliczeniowe i rekordy](../modules/04-vhdl/04.02-typy-std-logic-wektory-numeric-std-integer-typy.md)

1. **Jaka jest różnica między `std_logic` a `std_ulogic`?**

<details>
<summary>Odpowiedź</summary>

Oba mają te same 9 wartości. `std_ulogic` jest nierozstrzygany — sygnał tego typu może mieć tylko jeden sterownik, a drugi to błąd kompilacji. `std_logic` jest podtypem rozstrzyganym: wiele sterowników jest dozwolonych, a wynik wylicza funkcja rozstrzygająca (np. `'0'` i `'1'` daje `'X'`). W kodzie syntezowalnym `std_ulogic` wykrywa przypadkowe wielokrotne sterowanie już przy kompilacji.
</details>

2. **Jak dodać dwie liczby `std_logic_vector` ze znakiem z zachowaniem przeniesienia?**

<details>
<summary>Odpowiedź</summary>

`sum <= resize(signed(a), N + 1) + resize(signed(b), N + 1);` — zmiana typu na `signed`, poszerzenie z powieleniem bitu znaku, dodawanie na N + 1 bitach. Wynik z powrotem: `std_logic_vector(sum)`.
</details>

3. **Ile bitów zajmie `signal x : integer range 0 to 1000;`?**

<details>
<summary>Odpowiedź</summary>

10 bitów, bo $2^{10} = 1024 > 1000$. Syntezator wyznacza szerokość z zakresu. Bez zakresu `integer` miałby 32 bity.
</details>

### [04.03 — Instrukcje współbieżne: przypisania, when-else, with-select](../modules/04-vhdl/04.03-instrukcje-wspolbiezne-przypisania-when-else.md)

1. **Czym różni się `when … else` od `with … select`?**

<details>
<summary>Odpowiedź</summary>

`when … else` sprawdza warunki po kolei i wybiera pierwszy spełniony — tworzy łańcuch priorytetowy; warunki mogą się nakładać i dotyczyć różnych sygnałów. `with … select` wybiera wartość według jednego wyrażenia i stałych, rozłącznych wyborów — tworzy multiplekser bez priorytetu; musi pokryć wszystkie wartości (`when others`).
</details>

2. **Czy kolejność przypisań współbieżnych w architekturze ma znaczenie?**

<details>
<summary>Odpowiedź</summary>

Nie. Każde przypisanie współbieżne to osobny proces reagujący na zmiany swoich wejść; wszystkie działają równolegle, jak elementy na schemacie. Kolejność ma znaczenie tylko dla instrukcji wewnątrz procesu.
</details>

### [04.04 — Procesy, lista wrażliwości, sygnały a zmienne](../modules/04-vhdl/04.04-procesy-lista-wrazliwosci-sygnaly-a-zmienne.md)

1. **Czym różni się sygnał od zmiennej w VHDL?**

<details>
<summary>Odpowiedź</summary>

Sygnał (`<=`) dostaje nową wartość dopiero po zawieszeniu procesu — w następnym cyklu delta; w jednym przebiegu procesu jego odczyt zwraca starą wartość, a z kilku przypisań obowiązuje ostatnie. Zmienna (`:=`) zmienia wartość natychmiast i jest widoczna tylko w procesie. W procesie taktowanym łańcuch przypisań sygnałów tworzy łańcuch rejestrów, a łańcuch przypisań zmiennych — logikę; zmienna czytana przed zapisem staje się rejestrem.
</details>

2. **Ile rejestrów powstanie z kodu poniżej?**

```vhdl
process (clk)
  variable t : unsigned(7 downto 0);
begin
  if rising_edge(clk) then
    t := a + b;
    y <= t + c;
  end if;
end process;
```

<details>
<summary>Odpowiedź</summary>

8 rejestrów — tylko `y`. Zmienna `t` jest zapisywana przed odczytem, więc jest wynikiem pośrednim (sumator kombinacyjny), a cała suma `a + b + c` trafia do rejestru `y` w jednym takcie. Gdyby `t` był sygnałem, powstałyby dwa stopnie rejestrów: `t` i `y`, a `y` zawierałby `a + b` z poprzedniego taktu plus `c`.
</details>

3. **Po co `process (all)`?**

<details>
<summary>Odpowiedź</summary>

W VHDL-2008 oznacza, że proces jest wrażliwy na wszystkie sygnały, które czyta. Eliminuje błąd niepełnej listy wrażliwości, który powoduje różnice między symulacją a syntezą. Odpowiednik `always @*` w Verilogu i `always_comb` w SystemVerilogu.
</details>

### [04.05 — Instrukcje sekwencyjne: if, case i pętle](../modules/04-vhdl/04.05-instrukcje-sekwencyjne-if-case-i-petle.md)

1. **Co powstanie w sprzęcie z pętli `for` w procesie?**

<details>
<summary>Odpowiedź</summary>

Syntezator rozwija pętlę: treść powtarza się tyle razy, ile jest iteracji, z indeksem zamienionym na stałą. Wszystko dzieje się w jednym przebiegu procesu, czyli w jednym takcie dla procesu taktowanego. Pętla nie może mieć liczby iteracji zależnej od sygnału, a algorytm wieloetapowy w czasie wymaga licznika lub automatu.
</details>

2. **Kiedy użyjesz `case`, a kiedy `if`?**

<details>
<summary>Odpowiedź</summary>

`case`, gdy wybieram według jednego wyrażenia i stałych, rozłącznych wartości — dekoder operacji, automat stanów; daje multiplekser bez priorytetu i jest czytelny. `if/elsif`, gdy warunki dotyczą różnych sygnałów, mogą się nakładać albo priorytet jest częścią specyfikacji (np. reset przed zezwoleniem, arbiter z priorytetem).
</details>

### [04.06 — Hierarchia: komponenty, instancjonowanie, generic i generate](../modules/04-vhdl/04.06-hierarchia-komponenty-instancjonowanie-generic.md)

1. **Czym różni się instancja komponentu od instancji bezpośredniej `entity work.x`?**

<details>
<summary>Odpowiedź</summary>

Instancja komponentu wymaga deklaracji `component` (kopii interfejsu), a wiązanie z rzeczywistą jednostką następuje przy elaboracji — kompilować można w dowolnej kolejności, a komponent może być czarną skrzynką (np. moduł Verilog, IP). Instancja bezpośrednia nie potrzebuje deklaracji, sprawdza zgodność portów przy analizie, ale jednostka musi być skompilowana wcześniej.
</details>

2. **Jak zbudować parametryzowany łańcuch N rejestrów, który dla N = 0 jest zwykłym połączeniem?**

<details>
<summary>Odpowiedź</summary>

`if N = 0 generate y <= x; end generate;` i `if N > 0 generate` z tablicą etapów i `for i in 0 to N - 1 generate` z instancją rejestru między `stage(i)` a `stage(i + 1)`. W VHDL-2008 można użyć `if … else generate`. Tak jest zbudowany `pipe_delay` w tej bazie.
</details>

### [04.07 — Pakiety, funkcje, procedury i atrybuty](../modules/04-vhdl/04.07-pakiety-funkcje-procedury-i-atrybuty.md)

1. **Czym różni się funkcja od procedury w VHDL?**

<details>
<summary>Odpowiedź</summary>

Funkcja zwraca jedną wartość, ma tylko parametry wejściowe i nie może zawierać `wait` — używa się jej w wyrażeniach, także w RTL. Procedura nie zwraca wartości, przekazuje wyniki przez parametry `out`/`inout` i w testbenchu może zawierać `wait`, więc nadaje się do opisu sekwencji w czasie (np. wysłanie ramki).
</details>

2. **Jak napisać funkcję VHDL działającą dla wektorów dowolnej długości?**

<details>
<summary>Odpowiedź</summary>

Parametr deklaruje się jako typ bez ograniczeń (`std_logic_vector` bez zakresu), a długość i indeksy odczytuje atrybutami (`'length`, `'range`, `'high`). Na początku funkcji warto zadeklarować alias z indeksami od `'length - 1 downto 0`, żeby kod działał też dla wycinków o innych indeksach. Wynik ma zakres zmiennej lokalnej zbudowanej z `'length`.
</details>

### [04.08 — VHDL-2008 i VHDL-2019 — co ułatwiają](../modules/04-vhdl/04.08-vhdl-2008-i-vhdl-2019-co-ulatwiaja.md)

1. **Co VHDL-2008 wnosi do kodu syntezowalnego?**

<details>
<summary>Odpowiedź</summary>

Najważniejsze: `process (all)` (koniec błędów listy wrażliwości), czytanie portów `out`, przypisania warunkowe w procesach, `case?` i operatory dopasowania z wartościami obojętnymi, operatory redukcji, warunkowe `generate` z `else`/`case`, wyrażenia w `port map`, generic typów i pakietów, tablice z elementami bez ograniczeń oraz pakiety `fixed_pkg` i `float_pkg`. Kod jest krótszy i bezpieczniejszy.
</details>

2. **Czym różni się `casez` od `case inside`?**

<details>
<summary>Odpowiedź</summary>

`casez` (Verilog) traktuje `z` i `?` jako wartości obojętne po obu stronach porównania, więc wartość `z` na sygnale wyboru pasuje do dowolnego wzorca — błąd może zostać ukryty. `case inside` (SV) traktuje wartości obojętne tylko we wzorcach, obsługuje też zakresy i listy wartości; z `unique` symulator zgłasza nakładające się gałęzie.
</details>

### [04.09 — Pułapki VHDL: rozdzielczość sygnałów, konwersje i delta cykle](../modules/04-vhdl/04.09-pulapki-vhdl-rozdzielczosc-sygnalow-konwersje-i.md)

1. **Co to jest cykl delta i dlaczego ma znaczenie?**

<details>
<summary>Odpowiedź</summary>

To krok symulacji wewnątrz jednej chwili czasu. Przypisania do sygnałów stają się widoczne w następnym kroku delta, więc wynik nie zależy od kolejności wykonywania procesów. Pułapka pojawia się, gdy zegar zostanie przepisany przez przypisanie (`clk_b <= clk`): zbocze `clk_b` następuje o deltę później, a procesy na `clk_b` widzą już nowe wartości z procesów na `clk` — symulacja pokazuje inne zachowanie niż sprzęt.
</details>

2. **Co się stanie, gdy dwa procesy przypiszą ten sam sygnał `std_logic`?**

<details>
<summary>Odpowiedź</summary>

Kompilacja przejdzie, bo `std_logic` jest typem rozstrzyganym. W symulacji funkcja rozstrzygająca połączy wartości — przy różnych wartościach `'0'` i `'1'` wynik to `'X'`. Synteza zgłosi błąd wielu sterowników (chyba że to bufory trójstanowe na pinie). Żeby wykryć to przy kompilacji, używa się `std_ulogic` dla sygnałów wewnętrznych.
</details>

3. **Dlaczego `signed(unsigned_value)` może dać zły wynik?**

<details>
<summary>Odpowiedź</summary>

Bo zmiana typu nie zmienia bitów, tylko ich interpretację: jeśli najstarszy bit liczby bez znaku jest ustawiony, po zmianie na `signed` liczba staje się ujemna (200 → −56 na 8 bitach). Trzeba najpierw poszerzyć wektor o jeden bit zerem (`resize` na `unsigned`), a dopiero potem zmienić typ.
</details>

## 05 — Verilog

### [05.01 — Moduły, porty, wire i reg](../modules/05-verilog/05.01-moduly-porty-wire-i-reg.md)

1. **Czym różni się `wire` od `reg`?**

<details>
<summary>Odpowiedź</summary>

`wire` to sieć — nie przechowuje wartości, jest sterowana przez `assign`, port albo wyjście instancji i może mieć wielu sterowników. `reg` to zmienna przypisywana w blokach proceduralnych (`always`, `initial`) i przechowująca wartość do następnego przypisania w symulacji. `reg` nie oznacza rejestru — w `always @*` daje logikę kombinacyjną, w `always @(posedge clk)` rejestr. W SystemVerilogu oba zastępuje `logic`.
</details>

2. **Czym różni się `==` od `===`?**

<details>
<summary>Odpowiedź</summary>

`==` porównuje wartości logiczne; jeśli w którymkolwiek argumencie jest `x` lub `z`, wynik to `x`. `===` porównuje dosłownie, łącznie z `x` i `z`, i zawsze daje 0 albo 1. `===` jest niesyntezowalny i używa się go w testbenchach.
</details>

### [05.02 — Operatory, liczby, rozmiar i znak](../modules/05-verilog/05.02-operatory-liczby-rozmiar-i-znak.md)

1. **Jaki będzie wynik: `wire [3:0] a = 4'd12, b = 4'd5; wire [3:0] s = a + b; wire [4:0] t = a + b;`?**

<details>
<summary>Odpowiedź</summary>

`s` = 1 (17 mod 16), bo wyrażenie liczy się na 4 bitach — szerokości lewej strony i argumentów. `t` = 17, bo lewa strona ma 5 bitów i argumenty są poszerzane przed dodawaniem.
</details>

2. **Jak sprawdzić jedną linijką, czy liczba jest potęgą dwójki?**

<details>
<summary>Odpowiedź</summary>

`(x != 0) && ((x & (x - 1)) == 0)`. Odjęcie 1 zamienia najmłodszą jedynkę na 0 i wszystkie zera pod nią na jedynki; AND z oryginałem zeruje najmłodszą jedynkę. Jeśli wynik jest zerem, jedynka była tylko jedna.
</details>

3. **Kiedy wyrażenie w Verilogu jest liczone ze znakiem?**

<details>
<summary>Odpowiedź</summary>

Tylko gdy wszystkie argumenty są ze znakiem (znak lewej strony przypisania nie ma wpływu). Wystarczy jeden argument bez znaku, wycinek albo konkatenacja i całe wyrażenie jest bez znaku. Liczby bez rozmiaru są ze znakiem, stałe z rozmiarem bez litery `s` — bez znaku.
</details>

### [05.03 — assign i always: logika kombinacyjna i sekwencyjna](../modules/05-verilog/05.03-assign-i-always-logika-kombinacyjna-i.md)

1. **Jak zrobisz eliminację drgań przycisku w FPGA?**

<details>
<summary>Odpowiedź</summary>

Najpierw synchronizator dwuprzerzutnikowy, bo przycisk jest asynchroniczny. Potem licznik, który liczy takty, w których zsynchronizowane wejście różni się od zapamiętanego stanu, i zeruje się przy każdej zgodności. Gdy różnica trwa ustalony czas (np. 10 ms), stan wyjścia zmienia się i generowany jest impuls jednego taktu. Alternatywa: próbkowanie wejścia rzadko (np. co 5 ms, z zezwoleniem z prescalera) i porównanie kilku próbek.
</details>

2. **Kiedy użyjesz `assign`, a kiedy `always @*`?**

<details>
<summary>Odpowiedź</summary>

`assign` dla prostych wyrażeń i multiplekserów `?:` — jest krótszy i nie może utworzyć zatrzasku. `always @*` (w SV `always_comb`), gdy logika wymaga `if`/`case`, kilku kroków obliczeń albo jeden blok liczy kilka powiązanych sygnałów. W bloku `always @*` trzeba przypisać każde wyjście w każdej ścieżce.
</details>

### [05.04 — Przypisania blokujące i nieblokujące — reguły Cummingsa](../modules/05-verilog/05.04-przypisania-blokujace-i-nieblokujace-reguly.md)

1. **Kiedy używasz przypisań blokujących, a kiedy nieblokujących?**

<details>
<summary>Odpowiedź</summary>

Nieblokujące (`<=`) w blokach taktowanych i zatrzaskach — wszystkie rejestry czytają wartości sprzed zbocza, wynik nie zależy od kolejności bloków i odpowiada sprzętowi. Blokujące (`=`) w blokach kombinacyjnych — kolejne linie widzą nowe wartości, blok wykonuje się raz. Nie mieszam obu w jednym bloku i nie przypisuję jednej zmiennej w kilku blokach.
</details>

2. **Co zrobi ten kod i dlaczego?**

```verilog
always @(posedge clk) begin
    a = b;
    b = a;
end
```

<details>
<summary>Odpowiedź</summary>

Nie zamieni wartości: po `a = b` zmienna `a` ma już wartość `b`, więc `b = a` przypisuje `b` jej własną wartość. Oba rejestry będą miały wartość `b`. Z `a <= b; b <= a;` obie prawe strony są liczone przed zapisem i wartości się zamieniają — tak jak w sprzęcie z dwoma przerzutnikami połączonymi na krzyż.
</details>

3. **Co to jest wyścig w symulacji Verilog?**

<details>
<summary>Odpowiedź</summary>

Sytuacja, w której wynik zależy od kolejności wykonywania procesów w tej samej chwili czasu, a ta kolejność nie jest określona przez standard. Typowa przyczyna: przypisania blokujące w blokach taktowanych, które czytają nawzajem swoje wyniki, albo testbench zmieniający wejścia na tym samym zboczu, na którym układ je próbkuje. Objaw: różne wyniki w różnych symulatorach lub po zmianie kolejności plików.
</details>

### [05.05 — Parametry, localparam, generate i instancjonowanie](../modules/05-verilog/05.05-parametry-localparam-generate-i-instancjonowanie.md)

1. **Czym różni się `parameter` od `localparam`?**

<details>
<summary>Odpowiedź</summary>

`parameter` może zostać zmieniony przy instancji (`#(.W(16))`) — to interfejs konfiguracyjny modułu. `localparam` jest stałą wewnętrzną, zwykle wyliczaną z parametrów (np. szerokość licznika z `$clog2`), i nie da się go nadpisać z zewnątrz. Stałe, których użytkownik nie powinien zmieniać, deklaruje się jako `localparam`.
</details>

2. **Jak przekazać tablicę N słów W-bitowych przez port w Verilogu-2001 i w SystemVerilogu?**

<details>
<summary>Odpowiedź</summary>

W Verilogu-2001 trzeba spłaszczyć ją do wektora `[N*W-1:0]` i wybierać słowa wycinkiem `x[i*W +: W]`. W SystemVerilogu można zadeklarować port jako tablicę spakowaną `logic [N-1:0][W-1:0]` (ten sam układ bitów) albo rozpakowaną `logic [W-1:0] x [N]`, i odwoływać się `x[i]`.
</details>

### [05.06 — Funkcje, zadania i dyrektywy kompilatora](../modules/05-verilog/05.06-funkcje-zadania-i-dyrektywy-kompilatora.md)

1. **Czym różni się `function` od `task` w Verilogu?**

<details>
<summary>Odpowiedź</summary>

Funkcja zwraca jedną wartość, wywołuje się ją w wyrażeniu i nie może zawierać kontroli czasu (`#`, `@`, `wait`) — jest syntezowalna jako logika kombinacyjna. Zadanie zwraca wyniki przez argumenty `output`/`inout`, jest instrukcją i może czekać na zdarzenia — używa się go głównie w testbenchach do sekwencji pobudzeń.
</details>

2. **Jak zaimplementujesz CRC w FPGA?**

<details>
<summary>Odpowiedź</summary>

Jako rejestr z logiką XOR liczącą nowy stan z bieżącego stanu i danych. Dla jednego bitu na takt — LFSR sterowany danymi. Dla bajtu lub słowa na takt — rozwinięta pętla (funkcja w HDL), którą syntezator zamienia na sieć XOR. Parametry wariantu (wielomian, wartość początkowa, odbicia, XOR końcowy) biorę z katalogu i sprawdzam układ na wartości kontrolnej dla „123456789”.
</details>

### [05.07 — Pułapki Verilogu: niejawne sieci, obcinanie, znak i wyścigi](../modules/05-verilog/05.07-pulapki-verilogu-niejawne-sieci-obcinanie-znak.md)

1. **Co to są niejawne sieci i jak się przed nimi chronić?**

<details>
<summary>Odpowiedź</summary>

Verilog automatycznie deklaruje jednobitowy `wire` dla niezadeklarowanego identyfikatora użytego w połączeniu portu lub `assign`. Literówka w nazwie sygnału tworzy wtedy nowy, niepodłączony przewód bez błędu kompilacji. Ochrona: `` `default_nettype none `` na początku każdego pliku (wtedy to błąd) i lint z ostrzeżeniem o niejawnych sieciach.
</details>

2. **Dlaczego nie używa się `casex`?**

<details>
<summary>Odpowiedź</summary>

Bo `casex` traktuje `x` i `z` jako wartości obojętne także w wyrażeniu wyboru, nie tylko we wzorcach. Sygnał z `x` (np. niezainicjalizowany rejestr) dopasuje się do pierwszej gałęzi, a symulacja pokaże poprawne działanie, którego sprzęt nie gwarantuje. Zamiast tego `casez` (ostrożnie) albo `case inside` w SystemVerilogu.
</details>

3. **Jak policzyć sumę kontrolną nagłówka IPv4 w FPGA?**

<details>
<summary>Odpowiedź</summary>

Sumuję słowa 16-bitowe nagłówka (z polem sumy wyzerowanym) w arytmetyce uzupełnienia do jedynki: akumulator 17-bitowy, przeniesienie dodawane z powrotem do bitu 0 (w każdym kroku albo na końcu, zwijając kilka razy). Wynik to negacja bitowa sumy. Przy odbiorze suma wszystkich słów łącznie z polem sumy daje `0xFFFF`, jeśli nagłówek jest poprawny.
</details>

## 06 — SystemVerilog do projektowania

### [06.01 — logic, always_comb, always_ff i always_latch](../modules/06-systemverilog-rtl/06.01-logic-always-comb-always-ff-i-always-latch.md)

1. **Czym różni się `always_comb` od `always @*`?**

<details>
<summary>Odpowiedź</summary>

`always_comb` wyznacza listę wrażliwości automatycznie także z sygnałów czytanych w funkcjach, wykonuje się raz na początku symulacji, zabrania przypisywania jego zmiennych w innych blokach i pozwala narzędziom zgłosić błąd, gdy blok tworzy zatrzask. `always @*` jest tylko blokiem z automatyczną listą wrażliwości, bez tych sprawdzeń.
</details>

2. **Dlaczego w SystemVerilogu zaleca się `logic` zamiast `wire` i `reg`?**

<details>
<summary>Odpowiedź</summary>

Bo `logic` może być sterowany zarówno przez `assign`, jak i w bloku proceduralnym, co usuwa sztuczny podział Veriloga, a jednocześnie dopuszcza tylko jeden sterownik — przypadkowe podwójne sterowanie jest błędem kompilacji. `wire` zostaje dla sieci z wieloma sterownikami (magistrale trójstanowe).
</details>

### [06.02 — Typy użytkownika: enum, struct, union, typedef i tablice spakowane](../modules/06-systemverilog-rtl/06.02-typy-uzytkownika-enum-struct-union-typedef-i.md)

1. **Czym różni się struktura spakowana od nierozpakowanej?**

<details>
<summary>Odpowiedź</summary>

Spakowana (`struct packed`) to wektor bitów z nazwanymi wycinkami: pola leżą obok siebie bez przerw, pierwsze pole to najstarsze bity, całość można rzutować na wektor, przesyłać przez porty i używać w arytmetyce. Nierozpakowana przypomina strukturę w C — pola są osobnymi zmiennymi, mogą mieć dowolne typy (także `real`, `string`), ale nie da się jej traktować jak wektora. W RTL używa się spakowanych.
</details>

2. **Po co `union packed`?**

<details>
<summary>Odpowiedź</summary>

Żeby te same bity widzieć na dwa sposoby: np. rejestr sterujący jako 32-bitowe słowo magistrali i jako pola bitowe, albo nagłówek pakietu jako słowa i jako pola protokołu. Wszystkie pola unii spakowanej mają tę samą szerokość, a zapis przez jedno pole jest od razu widoczny przez drugie — bez kodu konwersji.
</details>

### [06.03 — Pakiety i parametryzacja typami](../modules/06-systemverilog-rtl/06.03-pakiety-i-parametryzacja-typami.md)

1. **Jak współdzielić typy i stałe między modułami w SystemVerilogu?**

<details>
<summary>Odpowiedź</summary>

Przez pakiet (`package … endpackage`) z `typedef`, `localparam` i funkcjami `automatic`. Moduły importują go (`import pkg::*;` w module albo w nagłówku modułu) lub odwołują się z prefiksem `pkg::nazwa`. Pakiet kompiluje się przed modułami. Nie importuje się w przestrzeni `$unit`, bo wynik zależy od kolejności kompilacji.
</details>

2. **Do czego służy `parameter type`?**

<details>
<summary>Odpowiedź</summary>

Do pisania bloków niezależnych od typu danych — kolejek, linii opóźniających, rejestrów potokowych, multiplekserów — które działają tak samo dla bajtu, piksela czy całej struktury nagłówka. Szerokość typu odczytuje się `$bits(T)`. To odpowiednik `generic (type T)` w VHDL-2008 i szablonów w C++.
</details>

### [06.04 — Interfejsy i modporty](../modules/06-systemverilog-rtl/06.04-interfejsy-i-modporty.md)

1. **Jak działa uzgadnianie valid/ready i jakie są jego reguły?**

<details>
<summary>Odpowiedź</summary>

Nadawca ustawia `valid`, gdy ma dane, odbiorca `ready`, gdy może je przyjąć; słowo przechodzi w takcie, w którym oba są równe 1. Nadawca po ustawieniu `valid` nie może go cofnąć ani zmienić danych przed przesłaniem i nie może czekać na `ready` z ustawieniem `valid`. Odbiorca może czekać na `valid`. Dzięki temu nie ma zakleszczeń, a każda strona może wstrzymać przepływ.
</details>

2. **Co to jest bufor skid i po co się go stosuje?**

<details>
<summary>Odpowiedź</summary>

To rejestr potokowy dla magistrali valid/ready, w którym rejestrowany jest także sygnał `ready`. Ponieważ nadawca dowiaduje się o wstrzymaniu o takt później, w tym takcie może wysłać jeszcze jedno słowo — trafia ono do drugiego rejestru (bufora skid). Dzięki temu wszystkie sygnały między blokami są z rejestrów (krótkie ścieżki czasowe), a przepustowość zostaje pełna: jedno słowo na takt.
</details>

3. **Co dają interfejsy i modporty w SystemVerilogu?**

<details>
<summary>Odpowiedź</summary>

Grupują sygnały magistrali w jeden obiekt, więc porty modułów i instancje są krótkie, a pomyłka w połączeniu pojedynczego sygnału jest mało prawdopodobna. Modporty określają kierunki z perspektywy każdej strony i narzędzie sprawdza, czy moduł nie steruje sygnałem, który powinien tylko czytać. Interfejsy mogą zawierać parametry, funkcje i asercje protokołu.
</details>

### [06.05 — unique, priority i bezpieczne instrukcje case](../modules/06-systemverilog-rtl/06.05-unique-priority-i-bezpieczne-instrukcje-case.md)

1. **Czym różnią się `unique case` i `priority case`?**

<details>
<summary>Odpowiedź</summary>

`unique` obiecuje, że w każdym wykonaniu pasuje dokładnie jedna gałąź (lub `default`) — syntezator może zbudować multiplekser bez priorytetu, a symulator zgłasza naruszenie, gdy pasuje kilka gałęzi albo żadna. `priority` obiecuje, że pasuje co najmniej jedna gałąź i kolejność ma znaczenie — priorytet zostaje, a symulator zgłasza przypadek bez dopasowania. Oba zastępują dyrektywy `full_case`/`parallel_case`, które działały tylko w syntezie.
</details>

2. **Jak działa arbiter karuzelowy i czym różni się od arbitra z priorytetem stałym?**

<details>
<summary>Odpowiedź</summary>

Pamięta ostatnio obsłużonego klienta i przy następnym przydziale przeszukuje zgłoszenia od kolejnego numeru cyklicznie, więc obsłużony klient ma potem najniższy priorytet. Każdy czeka najwyżej N − 1 przydziałów. Arbiter z priorytetem stałym zawsze faworyzuje te same zgłoszenia — przy dużym obciążeniu klienci o niskim priorytecie mogą nie być obsłużeni nigdy.
</details>

### [06.06 — Asercje natychmiastowe w kodzie RTL](../modules/06-systemverilog-rtl/06.06-asercje-natychmiastowe-w-kodzie-rtl.md)

1. **Czym różnią się asercje natychmiastowe od współbieżnych?**

<details>
<summary>Odpowiedź</summary>

Natychmiastowe (`assert (…)`) są instrukcjami proceduralnymi sprawdzanymi w chwili wykonania — jak `if` z komunikatem błędu; sprawdzają warunki w jednej chwili. Współbieżne (`assert property`) są taktowane zegarem i opisują sekwencje w czasie, np. „po żądaniu w ciągu 4 taktów przyjdzie odpowiedź”; działają niezależnie od bloków proceduralnych i można je dowodzić formalnie.
</details>

2. **Jakie asercje dodałbyś do kolejki FIFO?**

<details>
<summary>Odpowiedź</summary>

Brak zapisu przy `full` i odczytu przy `empty` (chyba że projekt to dopuszcza), liczba elementów w zakresie 0…DEPTH, `full` i `empty` nigdy jednocześnie, brak `x` na danych wyjściowych przy `!empty`, a jako asercje współbieżne — że element zapisany zostanie odczytany w tej samej kolejności (z pomocą modelu referencyjnego) i że po resecie kolejka jest pusta.
</details>

### [06.07 — Co z SystemVeriloga obsługują narzędzia syntezy](../modules/06-systemverilog-rtl/06.07-co-z-systemveriloga-obsluguja-narzedzia-syntezy.md)

1. **Których konstrukcji SystemVeriloga używasz w kodzie syntezowalnym?**

<details>
<summary>Odpowiedź</summary>

`logic`, `always_ff`/`always_comb`, `typedef enum` z typem bazowym, `struct packed`, pakiety z typami i funkcjami `automatic`, `unique`/`priority case` z czytaniem ostrzeżeń, `case inside`, interfejsy z modportami do magistral, parametry typu w blokach bibliotecznych — o ile obsługuje je łańcuch narzędzi projektu. Nie używam klas, losowania ani pokrycia w RTL. Przed użyciem mniej typowej konstrukcji sprawdzam ją małym przypadkiem testowym w syntezatorze docelowym.
</details>

2. **Jak połączyć moduł VHDL z modułem SystemVerilog w jednym projekcie?**

<details>
<summary>Odpowiedź</summary>

Narzędzia producentów kompilują oba języki do wspólnej biblioteki i pozwalają na instancję w obie strony — w VHDL przez deklarację komponentu (albo `entity work.nazwa` w niektórych narzędziach), w SV zwykłą instancją modułu. Porty na granicy muszą być prostych typów: bity i wektory. Struktury, rekordy, interfejsy i typy wyliczeniowe trzeba rozpakować na wektory w cienkiej warstwie opakowania.
</details>

## 07 — Kodowanie pod syntezę — wzorce RTL

### [07.01 — Myślenie sprzętowe: kod HDL to schemat, nie program](../modules/07-kodowanie-pod-synteze/07.01-myslenie-sprzetowe-kod-hdl-to-schemat-nie.md)

1. **Co powstaje w sprzęcie z pętli `for` w bloku kombinacyjnym?**

<details>
<summary>Odpowiedź</summary>

Pętla jest rozwijana przy elaboracji: powstaje tyle kopii ciała pętli, ile obiegów, połączonych tak, jak przepływają przez nie zmienne. Liczba obiegów musi być znana przy elaboracji. Wszystkie kopie działają równocześnie w jednym takcie; jeśli każda iteracja zależy od poprzedniej, powstaje łańcuch, którego opóźnienie rośnie z liczbą obiegów.
</details>

2. **Masz policzyć maksimum z 64 wartości przy 200 MHz. Jak zaprojektujesz układ?**

<details>
<summary>Odpowiedź</summary>

Drzewo porównań zamiast łańcucha — 6 poziomów zamiast 63. Jeśli 6 poziomów komparatorów nie zmieści się w 5 ns, dodaję rejestry potoku między poziomami (np. co dwa poziomy), godząc się na opóźnienie kilku taktów; przepustowość zostaje jedna wartość na takt. Jeśli dane przychodzą po jednej na takt, wystarczy jeden komparator i rejestr — maksimum bieżące, 64 takty. Wybór zależy od tego, jak dane przychodzą i jakiego opóźnienia wymaga system.
</details>

3. **Dlaczego kolejność instrukcji w procesie ma znaczenie, skoro „wszystko działa równolegle”?**

<details>
<summary>Odpowiedź</summary>

Równolegle działają procesy i przypisania współbieżne. Wewnątrz jednego procesu kolejność określa, które przypisanie do tego samego sygnału jest ostatnie, a więc priorytet multiplekserów i to, czy zmienna jest czytana przed, czy po aktualizacji. Kolejność wpływa na kształt schematu, a nie na kolejność zdarzeń w czasie.
</details>

### [07.02 — Rejestry i reset: synchroniczny, asynchroniczny, bez resetu](../modules/07-kodowanie-pod-synteze/07.02-rejestry-i-reset-synchroniczny-asynchroniczny.md)

1. **Reset synchroniczny czy asynchroniczny — co wybierasz w FPGA i dlaczego?**

<details>
<summary>Odpowiedź</summary>

Zależy od wymagań, ale typowy wybór to reset asynchroniczny w ustawianiu i synchroniczny w zdejmowaniu (synchronizator resetu) — wyjścia przechodzą w stan bezpieczny bez zegara, a zdjęcie jest analizowane czasowo (*recovery/removal*). Reset czysto synchroniczny jest prostszy w analizie i odporny na zakłócenia, ale wymaga zegara. AMD zaleca reset synchroniczny i resetowanie jak najmniejszej liczby rejestrów; Intel dopuszcza asynchroniczny z synchronizowanym zdjęciem. Niezależnie od wyboru: resetuję tylko sterowanie, danych nie.
</details>

2. **Narysuj synchronizator resetu i wyjaśnij, po co dwa przerzutniki.**

<details>
<summary>Odpowiedź</summary>

Dwa przerzutniki szeregowo, oba z asynchronicznym resetem z wejścia, wejście pierwszego na stałe 1, wyjście drugiego (zanegowane) to reset dla logiki. Ustawienie — natychmiast w obu. Zdjęcie — jedynka przechodzi przez łańcuch na kolejnych zboczach. Pierwszy przerzutnik może się stać metastabilny, jeśli zdjęcie resetu wypadnie blisko zbocza; drugi daje mu cały okres zegara na ustalenie, więc reset zdejmowany jest czysto, synchronicznie z zegarem, w całej domenie w tym samym takcie.
</details>

3. **Dlaczego w FPGA nie resetuje się rejestrów danych?**

<details>
<summary>Odpowiedź</summary>

Bo to kosztuje i niczego nie daje: reset to dodatkowe obciążenie sieci o ogromnym rozgałęzieniu, utrudnia upakowanie (sygnały sterujące są wspólne dla LAB) i — najważniejsze — blokuje wnioskowanie bloków RAM, rejestrów przesuwnych w pamięci i rejestrów wewnątrz bloków DSP, które nie mają resetu albo mają go ograniczonego. Wartość danych bez towarzyszącego `valid` jest i tak ignorowana, a FPGA ustawia stan rejestrów przy konfiguracji.
</details>

### [07.03 — Niezamierzone zatrzaski i pętle kombinacyjne](../modules/07-kodowanie-pod-synteze/07.03-niezamierzone-zatrzaski-i-petle-kombinacyjne.md)

1. **Kiedy z bloku kombinacyjnego powstaje zatrzask i jak temu zapobiec?**

<details>
<summary>Odpowiedź</summary>

Gdy istnieje ścieżka przez blok, w której wyjście nie dostaje wartości — `if` bez `else`, `case` bez `default`, wyjście przypisane tylko w części gałęzi. Semantyka mówi „zachowaj poprzednią wartość”, więc syntezator buduje zatrzask. Zapobiegam wartościami domyślnymi wszystkich wyjść na początku bloku, `default` w `case`, używam `always_comb`/`process (all)` i traktuję ostrzeżenia syntezy o zatrzaskach jak błędy.
</details>

2. **Dlaczego zatrzaski są w FPGA niepożądane?**

<details>
<summary>Odpowiedź</summary>

Element logiczny FPGA ma przerzutnik; zatrzask realizuje się z LUT ze sprzężeniem zwrotnym albo przerzutnika w trybie zatrzasku. Analiza czasowa zatrzasków jest trudniejsza (przezroczystość przez pół okresu, *time borrowing*), narzędzia często traktują je jako pętle kombinacyjne, a sygnał zezwolenia zbudowany z logiki może mieć szpilki i otwierać zatrzask w przypadkowych chwilach. W efekcie zachowanie zależy od rozmieszczenia i opóźnień.
</details>

3. **Verilator zgłasza `UNOPTFLAT` dla wektora przeniesień w liczniku. Czy to błąd?**

<details>
<summary>Odpowiedź</summary>

Najczęściej nie: Verilator traktuje wektor jako jedną zmienną, więc `c[i+1] = f(c[i])` wygląda dla niego jak zależność zmiennej od samej siebie. Sprawdzam ścieżkę w komunikacie — jeśli bit zależy tylko od bitów o niższych indeksach, pętli nie ma i wystarczy atrybut `split_var` albo rozbicie wektora na osobne sygnały. Jeśli jakiś bit zależy od samego siebie przez logikę kombinacyjną — to prawdziwa pętla i trzeba ją przerwać rejestrem.
</details>

### [07.04 — Liczniki, dzielniki i clock enable](../modules/07-kodowanie-pod-synteze/07.04-liczniki-dzielniki-i-clock-enable.md)

1. **Potrzebujesz zdarzenia co 1 ms przy zegarze 100 MHz. Jak to zrobisz?**

<details>
<summary>Odpowiedź</summary>

Licznik modulo 100 000 (17 bitów) taktowany zegarem 100 MHz i rejestrowany impuls `tick` trwający jeden takt, gdy licznik osiąga 99 999. Logika, która ma działać co 1 ms, jest taktowana tym samym zegarem 100 MHz i zmienia stan tylko przy `tick = 1`. Nie tworzę zegara 1 kHz z bitu licznika — to nowa domena, zły *skew*, brak analizy czasowej.
</details>

2. **Czym różni się licznik synchroniczny od asynchronicznego (ripple counter) i dlaczego w FPGA używa się synchronicznego?**

<details>
<summary>Odpowiedź</summary>

W asynchronicznym każdy przerzutnik jest taktowany wyjściem poprzedniego — opóźnienia się sumują, bity zmieniają się w różnych chwilach, a każdy bit to osobna domena zegarowa. W synchronicznym wszystkie bity mają wspólny zegar, a logika następnego stanu wyznacza, które się zmieniają. W FPGA: zegary z logiki nie idą sieciami globalnymi, analiza czasowa ich nie obejmuje, a łańcuchy przeniesień i tak liczą szybko — więc tylko synchroniczne.
</details>

3. **Co to jest ograniczenie wielocyklowe i kiedy można je zastosować do logiki z clock enable?**

<details>
<summary>Odpowiedź</summary>

Informacja dla analizy czasowej, że dana ścieżka ma na propagację N okresów zegara, a nie jeden (`set_multicycle_path -setup N` i odpowiednie `-hold N-1`). Dla logiki z zezwoleniem można je zastosować, gdy rejestr źródłowy i docelowy zmieniają się tylko przy tym samym impulsie, który pojawia się co N taktów. Trzeba uważać — ograniczenie nałożone na zbyt szeroką grupę ścieżek ukrywa prawdziwe naruszenia.
</details>

### [07.05 — Rejestry przesuwne, LFSR i linie opóźniające](../modules/07-kodowanie-pod-synteze/07.05-rejestry-przesuwne-lfsr-i-linie-opozniajace.md)

1. **Jak zaimplementować w FPGA linię opóźniającą o 1024 takty dla danych 16-bitowych?**

<details>
<summary>Odpowiedź</summary>

Jako bufor pierścieniowy w pamięci blokowej: licznik adresu modulo 1024, w każdym takcie odczyt i zapis pod ten sam adres — odczyt zwraca dane zapisane 1024 takty wcześniej (tryb „old data”). To 16 Kbit, czyli dwa bloki M9K w MAX 10, zamiast 16 384 przerzutników. Można to napisać jawnie albo opisać rejestr przesuwny bez resetu i pozwolić syntezatorowi go zamienić (Quartus: `altshift_taps`). Opóźnienie trzeba sprawdzić symulacją, bo pamięć z rejestrami może dodać takt.
</details>

2. **Czym różni się LFSR Galois od Fibonacciego?**

<details>
<summary>Odpowiedź</summary>

Fibonacci: na wejście rejestru trafia XOR kilku wybranych bitów — jedna bramka XOR o wielu wejściach na ścieżce sprzężenia. Galois: wypadający bit jest XOR-owany do kilku pozycji przy przesunięciu — wiele bramek XOR o dwóch wejściach, każda na innej pozycji, więc krótsza ścieżka. Dla tego samego wielomianu oba mają ten sam okres, ale generują ciąg w innej kolejności/fazie.
</details>

### [07.06 — Wnioskowanie pamięci RAM i ROM](../modules/07-kodowanie-pod-synteze/07.06-wnioskowanie-pamieci-ram-i-rom.md)

1. **Napisz pamięć RAM, którą syntezator umieści w bloku pamięci. Jakie warunki musi spełnić kod?**

<details>
<summary>Odpowiedź</summary>

Tablica słów, zapis w bloku taktowanym pod jeden adres na port, odczyt w bloku taktowanym (rejestr danych wyjściowych lub adresu), bez resetu zawartości, z zachowaniem read-during-write, które blok obsługuje (zwykle stare dane przy przypisaniach nieblokujących). Liczba portów zgodna z blokiem (najwyżej dwa), szerokości i głębokości w zakresie konfiguracji bloku. Potem sprawdzam raport (*RAM Summary*), czy pamięć faktycznie trafiła do bloków.
</details>

2. **Co to jest read-during-write i dlaczego ma znaczenie?**

<details>
<summary>Odpowiedź</summary>

Sytuacja, w której w jednym takcie zapisujemy i czytamy ten sam adres. Odczyt może zwrócić stare dane, nowe dane albo wartość nieokreśloną — zależnie od trybu bloku. Kod RTL opisuje jedno zachowanie; jeśli blok go nie obsługuje, syntezator dodaje logikę obejścia albo zgłasza ostrzeżenie. Przy instancji rdzenia w trybie „don't care” symulacja i sprzęt mogą się różnić. W projekcie trzeba albo unikać kolizji, albo jawnie określić i przetestować oczekiwane zachowanie.
</details>

3. **Dlaczego ROM zapisany jako `case` w bloku taktowanym może trafić do pamięci, a ten sam `case` w bloku kombinacyjnym — nie?**

<details>
<summary>Odpowiedź</summary>

Blok pamięci ma odczyt synchroniczny — rejestruje adres na zboczu. `case` w bloku taktowanym opisuje dokładnie to: wartość pojawia się po zboczu. `case` kombinacyjny opisuje odczyt natychmiastowy, którego blok nie potrafi; syntezator zbuduje funkcję logiczną w LUT (a jeśli dalej za nią jest rejestr, może przenieść go do pamięci — ale to już decyzja optymalizatora).
</details>

### [07.07 — Wnioskowanie mnożarek i bloków DSP](../modules/07-kodowanie-pod-synteze/07.07-wnioskowanie-mnozarek-i-blokow-dsp.md)

1. **Jak napisać kod, żeby syntezator użył bloku DSP z rejestrami?**

<details>
<summary>Odpowiedź</summary>

Mnożenie operatorem `*` na argumentach mieszczących się w bloku, z jednakową znakowością; rejestry na wejściach i na wyjściu iloczynu w tym samym bloku taktowanym, bez resetu (albo z resetem, który blok obsługuje); dla MAC — akumulator bezpośrednio za rejestrem iloczynu, a w rodzinach z akumulatorem w bloku — w zapisie, który przewodnik producenta podaje jako wzorzec. Potem sprawdzam w raporcie liczbę bloków i to, czy rejestry zostały do nich wchłonięte.
</details>

2. **Ile bitów potrzebuje akumulator dla filtra FIR o 32 współczynnikach 16-bitowych i próbkach 12-bitowych?**

<details>
<summary>Odpowiedź</summary>

Iloczyn 16 × 12 bitów ze znakiem ma 28 bitów. Suma 32 iloczynów potrzebuje dodatkowych ⌈log₂32⌉ = 5 bitów — razem 33 bity w najgorszym przypadku. W praktyce można zmniejszyć, licząc rzeczywiste maksimum sumy |współczynników| × maksimum próbki, ale bez takiej analizy bezpiecznie jest przyjąć pełną szerokość.
</details>

### [07.08 — Parametryzacja i projekt wielokrotnego użytku](../modules/07-kodowanie-pod-synteze/07.08-parametryzacja-i-projekt-wielokrotnego-uzytku.md)

1. **Jak zaprojektujesz sparametryzowany blok biblioteczny, żeby inny zespół mógł go bezpiecznie użyć?**

<details>
<summary>Odpowiedź</summary>

Parametry z wartościami domyślnymi i dokumentacją dozwolonych zakresów, wielkości pochodne liczone wewnątrz, sprawdzenie parametrów przy elaboracji (`$error`/`assert`), szerokości portów wyrażone parametrami, udokumentowane opóźnienie i zachowanie protokołu (np. valid/ready). Do tego testy samosprawdzające uruchamiane w CI dla kilku zestawów parametrów, w tym skrajnych, i lint bez ostrzeżeń. Nazwane bloki `generate`, żeby ścieżki hierarchii były stabilne.
</details>

2. **Ile bitów ma suma 100 liczb 12-bitowych bez znaku?**

<details>
<summary>Odpowiedź</summary>

12 + ⌈log₂100⌉ = 12 + 7 = 19 bitów. Sprawdzenie: 100 × 4095 = 409 500 < 2¹⁹ = 524 288.
</details>

### [07.09 — Styl kodu, lint i przeglądy: Verilator, Verible, VSG](../modules/07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)

1. **Jak wprowadziłbyś lint w istniejącym projekcie z setkami ostrzeżeń?**

<details>
<summary>Odpowiedź</summary>

Najpierw uruchomić go w trybie raportu w CI, żeby liczba ostrzeżeń była widoczna i nie rosła (blokować tylko nowe — porównanie z zapisaną listą). Potem przejrzeć ostrzeżenia według kategorii: najpierw groźne (zatrzaski, wielokrotne sterowanie, obcięte szerokości, `<=`/`=`), potem resztę. Prawdziwe błędy poprawić, celowe konstrukcje wyłączyć lokalnie z komentarzem. Moduł po module przełączać na tryb ścisły. Formatowanie wprowadzić jednym osobnym zatwierdzeniem, żeby nie mieszać go ze zmianami logiki.
</details>

2. **Verilator zgłasza `WIDTHEXPAND` dla `count == MAX - 1`. Czy to błąd?**

<details>
<summary>Odpowiedź</summary>

Funkcjonalnie zwykle nie — stała 32-bitowa jest porównywana z rozszerzonym licznikiem i wynik jest poprawny, dopóki `MAX - 1` mieści się w szerokości licznika. Ale ostrzeżenie wskazuje na brak kontroli szerokości: jeśli `MAX` przekroczy zakres licznika, porównanie nigdy nie będzie prawdziwe, a kod tego nie zgłosi. Poprawka: stała o szerokości licznika (`localparam [W-1:0] LAST = MAX - 1`, w SV `W'(MAX - 1)`) i ewentualnie sprawdzenie parametru przy elaboracji.
</details>

3. **Co sprawdzasz w przeglądzie kodu RTL kolegi?**

<details>
<summary>Odpowiedź</summary>

Najpierw, czy CI przeszło (testy, lint, synteza) — to załatwia formalności. Potem logikę: czy blok robi to, co mówi specyfikacja, zachowanie w przypadkach brzegowych (reset, przepełnienia, pełna/pusta kolejka, jednoczesne zdarzenia), przejścia między domenami zegara, reset, szerokości arytmetyki, wnioskowanie pamięci i DSP, opóźnienia i protokoły (valid/ready), a także czy testbench naprawdę sprawdza to, co twierdzi — z modelem niezależnym od kodu i sprawdzeniem pokrycia.
</details>

## 08 — Automaty stanów i sterowanie

### [08.01 — Automat Moore'a i Mealy'ego w HDL — style kodowania](../modules/08-automaty-stanow/08.01-automat-moore-a-i-mealy-ego-w-hdl-style.md)

1. **Czym różni się automat Moore'a od Mealy'ego? Który wybierzesz?**

<details>
<summary>Odpowiedź</summary>

Moore — wyjścia zależą tylko od stanu, Mealy — od stanu i wejść. Mealy reaguje w tym samym takcie i zwykle ma mniej stanów, ale ma kombinacyjną ścieżkę z wejścia na wyjście (dłuższa ścieżka czasowa w odbiorcy, możliwe szpilki). Domyślnie wybieram Moore'a albo Mealy'ego z rejestrowanymi wyjściami; czystego Mealy'ego tam, gdzie potrzebna jest reakcja w tym samym takcie, np. `ready` w handshake'u, i tylko wewnątrz jednej domeny zegara.
</details>

2. **Jak zapisać automat, żeby jego wyjścia były wolne od szpilek i nie opóźnione o takt?**

<details>
<summary>Odpowiedź</summary>

Wyjścia jako rejestry liczone z następnego stanu (`y <= f(state_next)`) albo — przy kodowaniu one-hot / z wyjściami wbudowanymi w kod stanu — bezpośrednio z bitów rejestru stanu. Wtedy wyjście zmienia się na tym samym zboczu co stan i nie ma po drodze logiki kombinacyjnej.
</details>

### [08.02 — Kodowanie stanów: binarne, one-hot, Graya](../modules/08-automaty-stanow/08.02-kodowanie-stanow-binarne-one-hot-graya.md)

1. **Dlaczego w FPGA często używa się kodowania one-hot?**

<details>
<summary>Odpowiedź</summary>

FPGA ma dużo przerzutników (jeden w każdym elemencie logicznym) i LUT o kilku wejściach. W one-hot sprawdzenie stanu to jeden bit, a logika następnego stanu każdego bitu zależy zwykle od kilku sygnałów — mieści się w jednym lub dwóch LUT, więc automat jest szybki. Kosztem jest więcej przerzutników i wiele kodów nielegalnych; bezpieczne wykrywanie ich wszystkich jest drogie.
</details>

2. **Jak wymusić w Quartusie własne kodowanie stanów?**

<details>
<summary>Odpowiedź</summary>

Atrybutem `syn_encoding` na rejestrze stanu (Verilog) lub typie wyliczeniowym (VHDL): `"user"` — kody z kodu źródłowego, w VHDL lista kodów dla wartości typu, np. `"11 01 10 00"`; albo styl (`"one-hot"`, `"sequential"`, `"compact"`), ewentualnie z dopiskiem `"safe"`. Globalnie — opcją *State Machine Processing*. Wynik sprawdzam w raporcie *State Machines*.
</details>

### [08.03 — Bezpieczne automaty: stany nielegalne i odzyskiwanie](../modules/08-automaty-stanow/08.03-bezpieczne-automaty-stany-nielegalne-i.md)

1. **Co to jest bezpieczny automat stanów i jak go zrealizować w Quartusie?**

<details>
<summary>Odpowiedź</summary>

Automat, który ze stanu nielegalnego (kodu rejestru spoza listy stanów) przechodzi w określony sposób do stanu bezpiecznego, zwykle stanu resetu. W Quartusie: atrybut `syn_encoding = "safe"` na rejestrze lub typie stanu albo opcja *Safe State Machine* — syntezator dodaje logikę odzyskiwania do stanu resetu. Własna gałąź `default` w kodzie nie wystarcza, bo optymalizacja rozpoznanego automatu ją usuwa. Niezależnie od tego synchronizuję wszystkie wejścia asynchroniczne.
</details>

2. **Które kodowanie stanów wybierzesz dla automatu w układzie narażonym na promieniowanie?**

<details>
<summary>Odpowiedź</summary>

Kodowanie, w którym pojedyncze przekłamanie daje kod nielegalny — one-hot albo binarne z bitem parzystości (odległość Hamminga ≥ 2) — z jawną detekcją i reakcją (powrót do stanu bezpiecznego, zgłoszenie błędu). Gdy przekłamanie nie może przerwać pracy — potrójna redundancja rejestru stanu z głosowaniem (TMR) albo kod korekcyjny. Kodowanie binarne bez ochrony odpada: przekłamanie często daje inny legalny stan, którego nie da się wykryć.
</details>

### [08.04 — Eliminacja drgań styków i wykrywanie zboczy](../modules/08-automaty-stanow/08.04-eliminacja-drgan-stykow-i-wykrywanie-zboczy.md)

1. **Jak obsłużysz przycisk mechaniczny w układzie FPGA?**

<details>
<summary>Odpowiedź</summary>

Synchronizator z dwóch przerzutników, potem filtr drgań — licznik albo automat, który przyjmuje nowy poziom dopiero po kilku–kilkunastu milisekundach stabilności — i detektor zbocza dający impuls jednego taktu do dalszej logiki. Wszystko w jednej domenie zegara; do długich czasów — licznik albo wspólny impuls zezwolenia. W testbenchu sprawdzam drgania krótsze i dłuższe od czasu filtra.
</details>

2. **Dlaczego impuls zbocza zamiast poziomu do sterowania licznikiem naciśnięć?**

<details>
<summary>Odpowiedź</summary>

Poziom trwa tyle, ile naciśnięcie — miliony taktów; licznik zwiększany „gdy level = 1” liczyłby takty, a nie naciśnięcia. Impuls trwa dokładnie jeden takt na zdarzenie, więc logika reagująca na niego wykonuje się raz.
</details>

### [08.05 — Handshake valid/ready i przepływ danych](../modules/08-automaty-stanow/08.05-handshake-valid-ready-i-przeplyw-danych.md)

1. **Wyjaśnij handshake valid/ready. Kiedy dane zostają przesłane i jakie są reguły dla obu stron?**

<details>
<summary>Odpowiedź</summary>

Przesłanie następuje na zboczu, na którym `valid` i `ready` są równe 1. Źródło ustawia `valid`, gdy ma dane, niezależnie od `ready`, i trzyma `valid` z niezmienionymi danymi aż do przesłania. Odbiorca ustawia `ready`, gdy może przyjąć dane; może czekać na `valid` i zmieniać `ready` w dowolnym takcie. Dzięki tym regułom nie ma zakleszczenia i nie ma pętli kombinacyjnej `valid ↔ ready`.
</details>

2. **Jak uzyskać pełną przepustowość w bloku z rejestrem wyjściowym i dlaczego trzeba uważać na `ready`?**

<details>
<summary>Odpowiedź</summary>

Blok przyjmuje nowe dane, gdy rejestr wyjściowy jest pusty albo jest odbierany w tym samym takcie: `in_ready = !out_valid || out_ready`. Daje to jedno przesłanie na takt, ale `in_ready` zależy kombinacyjnie od `out_ready` — przy łańcuchu wielu bloków ścieżka `ready` przechodzi przez wszystkie i wydłuża ścieżkę krytyczną. Przerywa się ją buforem skid: dodatkowy rejestr pozwala zarejestrować `ready` bez utraty przepustowości.
</details>

### [08.06 — Ścieżka danych i sterowanie (FSMD) — prosty procesor sekwencyjny](../modules/08-automaty-stanow/08.06-sciezka-danych-i-sterowanie-fsmd-prosty.md)

1. **Co to jest FSMD i jak podzieliłbyś projekt dzielarki sekwencyjnej?**

<details>
<summary>Odpowiedź</summary>

Automat stanów sterujący ścieżką danych. Dla dzielarki sekwencyjnej (odejmowanie z przesunięciem): ścieżka danych — rejestr reszty, rejestr ilorazu, dzielnik, licznik bitów, odejmowanie i przesuwnik; status — znak różnicy i „licznik = 0”; sterowanie — stany IDLE (czekanie na `start`), LOAD, ITERATE (N razy: odejmij, jeśli nie ujemne — zapisz i ustaw bit ilorazu, przesuń), DONE (`done = 1`). Sterowanie generuje sygnały zapisu rejestrów i wyboru w multiplekserach.
</details>

2. **Jak zweryfikowałbyś prosty procesor?**

<details>
<summary>Odpowiedź</summary>

Model referencyjny na poziomie listy instrukcji (interpreter albo symulator ISA, np. Spike dla RISC-V) i porównanie strumienia zdarzeń: zapisy rejestrów, dostępy do pamięci, wyjścia — w kolejności, niezależnie od liczby taktów. Testy: krótkie programy na każdą instrukcję z przypadkami brzegowymi (przepełnienie, zero, skok na siebie), programy losowe, a na koniec gotowe zestawy testów architektury. Do tego asercje protokołów i pokrycie: każda instrukcja, każdy warunek skoku w obie strony.
</details>

## 09 — Symulacja i testbenche

### [09.01 — Jak działa symulator: zdarzenia, delta cykle, regiony planowania](../modules/09-symulacja-i-testbench/09.01-jak-dziala-symulator-zdarzenia-delta-cykle.md)

1. **Co to jest delta cykl i po co jest?**

<details>
<summary>Odpowiedź</summary>

Krok symulacji o zerowym czasie. W jednym delta cyklu symulator aktualizuje sygnały zaplanowane w poprzednim, a potem wykonuje procesy wrażliwe na te zmiany; procesy czytają bieżące wartości i planują nowe na następny delta cykl. Dzięki temu procesy wykonywane kolejno zachowują się tak, jakby działały równocześnie: wszystkie przerzutniki widzą stan sprzed zbocza, niezależnie od kolejności, w jakiej symulator je wykonuje.
</details>

2. **Dlaczego w Verilogu w blokach taktowanych używa się przypisań nieblokujących?**

<details>
<summary>Odpowiedź</summary>

Prawa strona `<=` jest liczona w regionie active, a lewa aktualizowana dopiero w regionie NBA, po wykonaniu wszystkich bloków. Każdy blok taktowany czyta więc wartości sprzed zbocza — jak przerzutniki w sprzęcie — i wynik nie zależy od kolejności wykonania bloków. Przypisania blokujące w kilku blokach taktowanych dają wyścig: wynik zależy od kolejności, a synteza buduje i tak przerzutniki, więc symulacja nie zgadza się ze sprzętem.
</details>

3. **W projekcie VHDL ktoś napisał `clk_int <= clk;` i taktuje część rejestrów `clk_int`. Co może pójść źle?**

<details>
<summary>Odpowiedź</summary>

`clk_int` zmienia się delta cykl po `clk`. Rejestry taktowane `clk_int` próbkują dane z rejestrów taktowanych `clk` już po ich aktualizacji — w symulacji dane „przeskakują” stopień potoku, choć w sprzęcie (gdzie to ten sam zegar) tak nie jest. Symulacja RTL nie odpowiada sprzętowi. Poprawka: jeden sygnał zegara dla wszystkich rejestrów.
</details>

### [09.02 — Pierwszy testbench: zegar, reset i pobudzenia](../modules/09-symulacja-i-testbench/09.02-pierwszy-testbench-zegar-reset-i-pobudzenia.md)

1. **Jak napiszesz testbench dla prostego układu synchronicznego?**

<details>
<summary>Odpowiedź</summary>

Moduł bez portów z generatorem zegara, resetem przez kilka taktów, instancją układu i blokiem pobudzeń. Dane zmieniam na zboczu opadającym albo z opóźnieniem po narastającym, żeby uniknąć wyścigu z układem. Powtarzalne sekwencje zamykam w zadaniach/procedurach. Każde wyjście sprawdzam automatycznie z wartością oczekiwaną, zliczam błędy i kończę symulację jednoznacznym komunikatem. Potem dodaję model referencyjny i losowe pobudzenia.
</details>

2. **Po co zatrzymywać zegar w testbenchu VHDL, skoro jest `std.env.finish`?**

<details>
<summary>Odpowiedź</summary>

`std.env.finish` istnieje od VHDL-2008. W starszych standardach symulacja kończy się, gdy nie ma już zaplanowanych zdarzeń — a zegar generuje je w nieskończoność. Zatrzymanie zegara warunkiem `when not done` daje naturalny koniec niezależnie od standardu i symulatora; w tej bazie robi się oba.
</details>

### [09.03 — Testbench samosprawdzający: model referencyjny i porównanie](../modules/09-symulacja-i-testbench/09.03-testbench-samosprawdzajacy-model-referencyjny-i.md)

1. **Z jakich części składa się testbench samosprawdzający?**

<details>
<summary>Odpowiedź</summary>

Generator pobudzeń (ukierunkowanych i losowych, z kontrolowanym rozkładem i ziarnem), sterownik podający je zgodnie z protokołem, monitor zbierający wyjścia, model referencyjny liczący wynik oczekiwany, tablica wyników porównująca oba strumienie, pomiar pokrycia i podsumowanie z jednoznacznym wynikiem. W UVM i OSVVM te części mają formalne nazwy i klasy, ale idea jest ta sama.
</details>

2. **Twój test losowy przechodzi od miesięcy. Skąd wiesz, że coś sprawdza?**

<details>
<summary>Odpowiedź</summary>

Z pomiaru pokrycia: listy zaplanowanych przypadków (wartości skrajne, przepełnienia, wszystkie stany automatu, kombinacje sygnałów sterujących) i liczników, ile razy test w nie trafił. Do tego liczba sprawdzeń w podsumowaniu i test „mutacyjny”: celowo wprowadzony błąd w układzie musi zostać wykryty. Bez tego „PASS” może znaczyć tylko, że test nic nie porównuje.
</details>

### [09.04 — Przebiegi: VCD, FST, GTKWave, Surfer i Questa](../modules/09-symulacja-i-testbench/09.04-przebiegi-vcd-fst-gtkwave-surfer-i-questa.md)

1. **Symulacja trwa godzinę i produkuje 50 GB VCD. Co zrobisz?**

<details>
<summary>Odpowiedź</summary>

Przejdę na format skompresowany (FST, WLF), ograniczę zakres hierarchii (`$dumpvars(1, …)` dla wybranych modułów), włączę zapis tylko w oknie czasu wokół problemu (`$dumpon`/`$dumpoff` sterowane warunkiem albo numerem taktu z testbencha) i wykorzystam powtarzalność — ziarno i numer taktu błędu z pierwszego przebiegu, zapis tylko w drugim. Najlepiej, żeby błąd wskazywała asercja lub tablica wyników z dokładnym czasem.
</details>

### [09.05 — Wektory testowe z plików](../modules/09-symulacja-i-testbench/09.05-wektory-testowe-z-plikow.md)

1. **Masz model algorytmu filtru w Pythonie. Jak zweryfikujesz implementację w HDL?**

<details>
<summary>Odpowiedź</summary>

Rozszerzam model o wierne odwzorowanie arytmetyki stałoprzecinkowej (szerokości, zaokrąglenia, nasycenia), generuję nim wektory: wejścia i oczekiwane wyjścia takt po takcie (albo strumień próbek, jeśli opóźnienie układu jest znane), zapisuję do pliku i czytam w testbenchu. Scenariusze: impuls, skok, sinusy różnych częstotliwości, wartości skrajne, szum losowy. W kolejnym kroku — cocotb, czyli model w Pythonie podłączony bezpośrednio do symulatora, bez plików pośrednich.
</details>

### [09.06 — Symulacja po syntezie i z opóźnieniami](../modules/09-symulacja-i-testbench/09.06-symulacja-po-syntezie-i-z-opoznieniami.md)

1. **Po co symulacja po syntezie, skoro jest symulacja RTL i analiza czasowa?**

<details>
<summary>Odpowiedź</summary>

Sprawdza, czy synteza zinterpretowała kod tak samo jak symulator: wykrywa rozbieżności wynikające z wyścigów, niepełnych list wrażliwości, inicjalizacji, dyrektyw syntezy, usuniętej logiki i błędów narzędzi. Analiza czasowa sprawdza czasy, ale zakłada, że funkcja netlisty jest poprawna. W praktyce uruchamia się ją dla wybranych testów, nie dla całej regresji, bo jest wolniejsza.
</details>

2. **Dlaczego producenci FPGA odchodzą od symulacji czasowej netlisty?**

<details>
<summary>Odpowiedź</summary>

Jest bardzo wolna, sprawdza tylko scenariusze pokryte testem i daje wyniki zależne od modelu opóźnień, a statyczna analiza czasowa sprawdza wszystkie ścieżki we wszystkich narożnikach procesowo-napięciowo-temperaturowych w ciągu minut. Przy synchronicznym projekcie z poprawnymi ograniczeniami i zsynchronizowanymi przejściami między domenami symulacja czasowa nie wnosi nic, czego nie da się sprawdzić statycznie — dlatego nowsze rodziny (Cyclone V i nowsze, MAX 10) jej w Quartusie nie obsługują.
</details>

### [09.07 — Regresja i automatyzacja: skrypty, Makefile, CI](../modules/09-symulacja-i-testbench/09.07-regresja-i-automatyzacja-skrypty-makefile-ci.md)

1. **Jak zorganizowałbyś regresję dla projektu FPGA w zespole?**

<details>
<summary>Odpowiedź</summary>

Testbenche samosprawdzające z jednoznacznym wynikiem, uruchamiane jednym poleceniem (Makefile, VUnit, cocotb) lokalnie i w CI przy każdym pull requeście: lint, symulacja wszystkich testów krótkich, synteza (open source albo na maszynie z narzędziami producenta), raport z tabelą wyników i artefaktami (logi, przebiegi błędnych testów). Długie testy — wiele ziaren, pokrycie, symulacja po syntezie, pełna implementacja z analizą czasową — w przebiegu nocnym. Wyniki pokrycia zbierane w czasie, żeby widzieć, co nie jest testowane.
</details>

2. **Test przechodzi lokalnie, a w CI nie. Od czego zaczniesz?**

<details>
<summary>Odpowiedź</summary>

Porównam wersje narzędzi i opcje uruchomienia (log CI), ścieżki i katalog roboczy (pliki danych, pliki względne), ziarno losowania i zależność od kolejności testów, różnice platformy (koniec wierszy, wielkość liter w nazwach plików) i limity czasu. Odtworzę przebieg lokalnie tym samym poleceniem co w CI — najlepiej w tym samym obrazie systemu lub kontenerze.
</details>

## 10 — Weryfikacja w SystemVerilogu

### [10.01 — Programowanie obiektowe: klasy, dziedziczenie, polimorfizm](../modules/10-weryfikacja-systemverilog/10.01-programowanie-obiektowe-klasy-dziedziczenie.md)

1. **Czym różni się kopia płytka od głębokiej w SystemVerilogu i kiedy ma to znaczenie w testbenchu?**

<details>
<summary>Odpowiedź</summary>

`new obj` tworzy kopię płytką: nowy obiekt z kopiami wartości pól, ale pola-uchwyty wskazują te same obiekty co w oryginale. Kopia głęboka wymaga własnej metody, która tworzy nowe obiekty dla pól-uchwytów. Ma to znaczenie przy przekazywaniu transakcji między komponentami (monitor → scoreboard, generator → driver): jeśli nadawca później zmienia obiekt, odbiorca widzi zmianę. Rozwiązanie: nowy obiekt dla każdej transakcji albo `clone()` przed wysłaniem.
</details>

2. **Do czego służą metody wirtualne w testbenchu?**

<details>
<summary>Odpowiedź</summary>

Pozwalają, żeby kod napisany dla klasy bazowej (generator, scoreboard, środowisko) działał z potomkami bez zmian: wywołanie przez uchwyt bazowy uruchamia wersję z klasy obiektu. Typowe użycie: wariant transakcji z innymi ograniczeniami albo inny sposób drukowania, podstawiony przez test; w UVM — mechanizm *factory override*.
</details>

3. **Co zwraca `$cast` i kiedy rzutowanie w dół się nie uda?**

<details>
<summary>Odpowiedź</summary>

Wywołany jako funkcja zwraca 1 przy sukcesie i 0 przy porażce (jako zadanie — błąd wykonania). Rzutowanie z uchwytu bazowego na uchwyt potomka udaje się tylko wtedy, gdy wskazywany obiekt naprawdę jest tej klasy potomka (albo jej potomkiem).
</details>

### [10.02 — Losowanie z ograniczeniami (constrained random)](../modules/10-weryfikacja-systemverilog/10.02-losowanie-z-ograniczeniami-constrained-random.md)

1. **Mając `rand bit sel; rand bit [7:0] v; constraint c { sel -> v == 0; }`, jak często `sel` będzie równe 1? Jak to zmienić?**

<details>
<summary>Odpowiedź</summary>

Rozwiązań jest 257 (256 z `sel = 0`, jedno z `sel = 1`), a losowanie jest równomierne po rozwiązaniach, więc P(`sel` = 1) = 1/257. `solve sel before v` sprawia, że `sel` jest losowane najpierw z rozkładem ½ / ½; można też użyć `sel dist {0 := 1, 1 := 1}`.
</details>

2. **Czym różni się `rand` od `randc`?**

<details>
<summary>Odpowiedź</summary>

`rand` — każde losowanie niezależne, wartości mogą się powtarzać. `randc` — losowanie cykliczne: kolejne wywołania dają permutację wszystkich możliwych wartości bez powtórzeń, a dopiero po wyczerpaniu zaczyna się nowa permutacja. Przydatne np. do przejścia przez wszystkie adresy albo kody operacji w losowej kolejności.
</details>

3. **Co się dzieje, gdy ograniczenia są sprzeczne?**

<details>
<summary>Odpowiedź</summary>

`randomize()` zwraca 0, zmienne losowane zachowują poprzednie wartości, `post_randomize()` nie jest wywoływane. Symulatory zwykle wypisują ostrzeżenie ze wskazaniem ograniczeń. Testbench powinien sprawdzić wynik i zgłosić błąd, a nie kontynuować na starych wartościach.
</details>

### [10.03 — Pokrycie funkcjonalne: covergroup, coverpoint, cross](../modules/10-weryfikacja-systemverilog/10.03-pokrycie-funkcjonalne-covergroup-coverpoint.md)

1. **Czym różni się pokrycie funkcjonalne od pokrycia kodu? Czy 100 % pokrycia kodu wystarcza?**

<details>
<summary>Odpowiedź</summary>

Pokrycie kodu symulator liczy automatycznie z RTL (wiersze, gałęzie, wyrażenia, przełączenia, stany FSM); pokrycie funkcjonalne definiuje inżynier na podstawie specyfikacji (`covergroup`, `cover property`). 100 % pokrycia kodu nie wystarcza: nie wykrywa brakującej funkcji (kodu, którego nie ma, nie da się nie pokryć), nie mówi, czy wynik był sprawdzony, ani czy wystąpiły kombinacje i kolejności zdarzeń. Potrzebne są oba rodzaje.
</details>

2. **Masz 32-bitowy argument. Jak zdefiniujesz dla niego kosze?**

<details>
<summary>Odpowiedź</summary>

Nie wszystkie wartości ani domyślne kosze automatyczne. Klasy ze specyfikacji: 0, 1, maksimum, wartości ze znakiem (najmniejsza ujemna, −1), potęgi dwójki lub pojedyncze bity, jeśli mają znaczenie, oraz zakresy „pozostałe małe/duże”. Do tego krzyżowanie z kodem operacji tylko tam, gdzie kombinacja ma znaczenie, i wykluczenia dla kombinacji nieosiągalnych.
</details>

3. **Pokrycie utknęło na 95 %. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Sprawdzam w raporcie, które kosze są puste. Dla każdego: czy jest osiągalny (jeśli nie — `ignore_bins`/`iff` z uzasadnieniem w planie weryfikacji), czy ograniczenia go nie wykluczają albo czynią bardzo rzadkim (zmiana wag, `solve…before`, nowa klasa transakcji), czy potrzebny jest test ukierunkowany. Samo wydłużanie losowania jest ostatnią opcją.
</details>

### [10.04 — Asercje SVA: sekwencje i właściwości](../modules/10-weryfikacja-systemverilog/10.04-asercje-sva-sekwencje-i-wlasciwosci.md)

1. **Czym różni się `|->` od `|=>`? Zapisz regułę „po żądaniu `req` odpowiedź `ack` w ciągu 1–3 taktów”.**

<details>
<summary>Odpowiedź</summary>

`A |-> B` — `B` sprawdzane od tego samego taktu, w którym zakończył się `A`; `A |=> B` — od następnego taktu, czyli `A |-> ##1 B`. Reguła: `assert property (@(posedge clk) disable iff (rst) req |-> ##[1:3] ack);`. Do tego `cover property (req ##[1:3] ack);` i najlepiej druga asercja, że `ack` nie pojawia się bez wcześniejszego `req`.
</details>

2. **Co to jest sukces pusty (vacuous success) i jak się przed nim bronić?**

<details>
<summary>Odpowiedź</summary>

Implikacja jest spełniona, gdy poprzednik nie zachodzi — asercja „przechodzi”, choć niczego nie sprawdziła. Obrona: `cover property` dla poprzednika (lub całego scenariusza) z wymaganiem, by był osiągnięty; przegląd raportów pokrycia asercji (symulatory raportują osobno sukcesy puste i niepuste).
</details>

3. **Kiedy użyjesz `assume` zamiast `assert`?**

<details>
<summary>Odpowiedź</summary>

Gdy reguła opisuje zachowanie otoczenia układu (np. źródło trzyma `valid` i dane do przyjęcia, nie wysyła kodów zabronionych). W symulacji `assume` sprawdza testbench jak asercja, w weryfikacji formalnej ogranicza przestrzeń pobudzeń — bez założeń narzędzie formalne znajdzie „błędy” wywołane nielegalnym wejściem.
</details>

### [10.05 — Testbench warstwowy: driver, monitor, scoreboard](../modules/10-weryfikacja-systemverilog/10.05-testbench-warstwowy-driver-monitor-scoreboard.md)

1. **Jakie komponenty ma typowy testbench warstwowy i za co każdy odpowiada?**

<details>
<summary>Odpowiedź</summary>

Generator (sekwencer) tworzy transakcje według scenariusza; driver zamienia je na sygnały zgodnie z protokołem; monitor obserwuje sygnały i odtwarza transakcje (pasywnie, bez wiedzy drivera); scoreboard porównuje wyniki z modelem referencyjnym; kolektor pokrycia mierzy, co sprawdzono; środowisko tworzy i łączy komponenty, test konfiguruje scenariusz. W UVM odpowiadają im `uvm_sequence`/`uvm_sequencer`, `uvm_driver`, `uvm_monitor`, `uvm_scoreboard`, `uvm_subscriber`, `uvm_env`, `uvm_test`.
</details>

2. **Po co wirtualny interfejs?**

<details>
<summary>Odpowiedź</summary>

Klasy powstają dynamicznie i nie mają portów, a interfejsy i moduły są statyczne. Wirtualny interfejs to uchwyt do egzemplarza interfejsu przekazywany do obiektu — klasa może sterować i obserwować sygnały, a ten sam kod klasy działa z dowolnym egzemplarzem (kilka portów, kilka układów).
</details>

3. **Jak sprawdzisz, że Twój testbench naprawdę wykrywa błędy?**

<details>
<summary>Odpowiedź</summary>

Wstrzykuję błędy do układu (ręcznie przez parametr lub `define`, albo automatycznie narzędziem do mutacji, np. `mcy` z Yosysa) i sprawdzam, czy testy je wykrywają. Dodatkowo: pokrycie funkcjonalne i kodu, przegląd asercji `cover`, porównanie z niezależnym modelem.
</details>

### [10.06 — Komunikacja i współbieżność: mailbox, semafory, zdarzenia, fork-join](../modules/10-weryfikacja-systemverilog/10.06-komunikacja-i-wspolbieznosc-mailbox-semafory.md)

1. **Czym różnią się `join`, `join_any` i `join_none`? Jak zakończyć pozostałe gałęzie po `join_any`?**

<details>
<summary>Odpowiedź</summary>

`join` czeka na wszystkie gałęzie, `join_any` na pierwszą (pozostałe działają dalej), `join_none` nie czeka wcale (gałęzie startują, gdy rodzic się zablokuje). Pozostałe gałęzie kończy `disable fork` — trzeba pamiętać, że dotyczy wszystkich potomków procesu, więc w razie potrzeby zawęża się go dodatkowym `fork…join` dookoła.
</details>

2. **Dlaczego `@ev` może się zawiesić, a `wait(ev.triggered)` nie?**

<details>
<summary>Odpowiedź</summary>

`@ev` czeka na wyzwolenie, które nastąpi po rozpoczęciu czekania. Jeśli inny proces wyzwolił zdarzenie wcześniej w tym samym kroku czasu, czekający go nie zobaczy. `ev.triggered` jest prawdziwe przez resztę kroku czasu, w którym nastąpiło wyzwolenie, więc `wait` przejdzie niezależnie od kolejności procesów.
</details>

3. **Kiedy użyjesz semafora, a kiedy skrzynki?**

<details>
<summary>Odpowiedź</summary>

Semafor — do wzajemnego wykluczania lub ograniczenia liczby równoczesnych dostępów do zasobu (wspólna magistrala, model pamięci, licznik kredytów); nie przenosi danych. Skrzynka — do przekazywania danych (transakcji) między procesami w kolejności FIFO, z opcjonalnym ograniczeniem pojemności jako przeciwciśnieniem.
</details>

### [10.07 — Plan weryfikacji i pokrycie kodu](../modules/10-weryfikacja-systemverilog/10.07-plan-weryfikacji-i-pokrycie-kodu.md)

1. **Co powinien zawierać plan weryfikacji?**

<details>
<summary>Odpowiedź</summary>

Listę funkcji ze specyfikacji (także trybów błędów, resetu, przypadków brzegowych) z przypisanym sposobem sprawdzenia (model/scoreboard, asercja, test ukierunkowany, weryfikacja formalna), miarą (kosze pokrycia, `cover`), priorytetem i stanem; opis środowiska i założeń o otoczeniu; listę testów regresji; kryteria zakończenia (zero błędów, pokrycie funkcjonalne, pokrycie kodu z wyjaśnionymi wyłączeniami, liczba ziaren); listę wyłączeń z uzasadnieniem.
</details>

2. **Masz 100 % pokrycia funkcjonalnego i 85 % pokrycia gałęzi. Co z tego wynika?**

<details>
<summary>Odpowiedź</summary>

Model pokrycia funkcjonalnego nie obejmuje części zachowań, które istnieją w kodzie — albo plan o czymś zapomniał (trzeba dopisać kosze i testy), albo kod zawiera martwe lub nieosiągalne fragmenty (do usunięcia albo wyłączenia z uzasadnieniem). Trzeba przejrzeć niepokryte gałęzie jedna po drugiej.
</details>

3. **Czym różnią się pokrycie wyrażeń (condition) i gałęzi (branch)?**

<details>
<summary>Odpowiedź</summary>

Pokrycie gałęzi sprawdza, czy każda gałąź `if`/`case` została wybrana. Pokrycie wyrażeń sprawdza, czy każdy składnik złożonego warunku (np. `a && b || c`) choć raz samodzielnie zdecydował o wyniku — gałąź może być pokryta, choć `c` nigdy nie miało znaczenia.
</details>

## 11 — UVM — Universal Verification Methodology

### [11.01 — Po co metodologia: struktura środowiska UVM](../modules/11-uvm/11.01-po-co-metodologia-struktura-srodowiska-uvm.md)

1. **Opisz strukturę typowego środowiska UVM.**

<details>
<summary>Odpowiedź</summary>

Moduł górny z układem, interfejsami i `run_test()`; test (`uvm_test`) tworzy środowisko i uruchamia sekwencje; środowisko (`uvm_env`) zawiera agentów (po jednym na interfejs: sekwencer, driver, monitor; aktywny albo pasywny), scoreboard z modelem referencyjnym, kolektory pokrycia, model rejestrów z predyktorem. Komponenty komunikują się portami TLM (sekwencer–driver) i portami analizy (monitor → scoreboard/pokrycie), konfigurację dostają z `uvm_config_db`.
</details>

2. **Czym różni się `uvm_object` od `uvm_component`?**

<details>
<summary>Odpowiedź</summary>

Komponenty tworzone są w fazie budowy, mają rodzica i stałe miejsce w hierarchii, uczestniczą w fazach i istnieją przez całą symulację (test, środowisko, agent, driver, monitor, scoreboard). Obiekty są dynamiczne, bez hierarchii i faz — transakcje, sekwencje, konfiguracje, model rejestrów.
</details>

3. **Co to są sprzeciwy (objections) i po co są?**

<details>
<summary>Odpowiedź</summary>

Mechanizm kończenia faz czasowych: faza `run` trwa, dopóki choć jeden komponent lub sekwencja trzyma sprzeciw. Test podnosi sprzeciw przed uruchomieniem sekwencji i zdejmuje po zakończeniu; komponenty mogą przedłużyć test, np. scoreboard do opróżnienia kolejki. Opcjonalnie `set_drain_time` daje dodatkowy czas po zdjęciu ostatniego sprzeciwu.
</details>

### [11.02 — Komponenty, fazy i fabryka](../modules/11-uvm/11.02-komponenty-fazy-i-fabryka.md)

1. **Wymień fazy UVM. Dlaczego `build_phase` wykonuje się z góry na dół, a `connect_phase` z dołu do góry?**

<details>
<summary>Odpowiedź</summary>

`build`, `connect`, `end_of_elaboration`, `start_of_simulation`, `run` (oraz równoległe fazy szczegółowe `reset`/`configure`/`main`/`shutdown`), `extract`, `check`, `report`, `final`. `build` z góry, bo rodzic tworzy dzieci i ustawia ich konfigurację, zanim się zbudują; `connect` z dołu, bo połączenia między komponentami wymagają, by wszystkie dzieci i ich porty już istniały, a rodzic łączy gotowe poddrzewa.
</details>

2. **Do czego służy fabryka UVM? Podaj przykład użycia.**

<details>
<summary>Odpowiedź</summary>

Pozwala zmienić typ tworzonego obiektu lub komponentu bez zmiany kodu, który go tworzy. Przykłady: test błędów podmienia driver na wersję wstrzykującą błędy protokołu; test podmienia transakcję na wersję z innymi ograniczeniami (np. tylko zapisy, długie opóźnienia); środowisko systemowe podmienia monitor na wersję z dodatkowym pokryciem. Warunek: tworzenie przez `type_id::create()` i dziedziczenie nowego typu po starym.
</details>

### [11.03 — Transakcje, sekwencje i sekwencer](../modules/11-uvm/11.03-transakcje-sekwencje-i-sekwencer.md)

1. **Opisz uzgadnianie między sekwencją, sekwencerem i driverem.**

<details>
<summary>Odpowiedź</summary>

Sekwencja wywołuje `start_item` — sekwencer kolejkuje prośbę i po arbitrażu przydziela dostęp; sekwencja losuje transakcję i wywołuje `finish_item`, które przekazuje ją driverowi oczekującemu w `get_next_item`. Driver steruje interfejsem i wywołuje `item_done` (opcjonalnie z odpowiedzią), co odblokowuje `finish_item`. Przy odpowiedziach osobnymi obiektami: `put_response` w driverze i `get_response` w sekwencji, z dopasowaniem po identyfikatorze transakcji.
</details>

2. **Czym jest sekwencja wirtualna?**

<details>
<summary>Odpowiedź</summary>

Sekwencja bez własnych transakcji, uruchamiana na sekwencerze wirtualnym (albo bez sekwencera), która koordynuje sekwencje na sekwencerach kilku agentów — ustala kolejność i równoległość scenariuszy dla całego układu, np. najpierw konfiguracja przez magistralę rejestrów, potem równoległy ruch na dwóch portach danych.
</details>

### [11.04 — Agent, driver i monitor](../modules/11-uvm/11.04-agent-driver-i-monitor.md)

1. **Jakie są zasady handshake w AXI? Czy slave może czekać na `VALID` przed ustawieniem `READY`?**

<details>
<summary>Odpowiedź</summary>

Przesłanie zachodzi na zboczu, gdy `VALID` i `READY` są równe 1. Nadawca po ustawieniu `VALID` musi go trzymać razem z niezmienionymi danymi do przesłania i nie może uzależniać `VALID` od `READY`. Odbiorca może czekać na `VALID` przed ustawieniem `READY` (i może ustawić `READY` wcześniej). Dla zapisu slave nie może wymagać kolejności AW/W; odpowiedź B dopiero po obu przesłaniach.
</details>

2. **Kiedy agent jest pasywny?**

<details>
<summary>Odpowiedź</summary>

Gdy środowisko obserwuje interfejs, którym steruje ktoś inny — inny blok w środowisku systemowym, rzeczywisty procesor, albo strona wyjściowa układu. Pasywny agent ma tylko monitor (i ewentualnie pokrycie); ten sam kod agenta służy do obu trybów przez pole `is_active` w konfiguracji.
</details>

### [11.05 — Scoreboard, porty analizy i pokrycie](../modules/11-uvm/11.05-scoreboard-porty-analizy-i-pokrycie.md)

1. **Czym różni się port analizy od portu `put`/`get` w TLM?**

<details>
<summary>Odpowiedź</summary>

Port analizy realizuje rozgłaszanie: `write()` jest funkcją bez czasu, może mieć dowolną liczbę odbiorców (także zero) i nadawca nie czeka na nich. Porty `put`/`get` łączą jednego nadawcę z jednym odbiorcą, mogą blokować (zadania) i służą do przekazywania transakcji z kontrolą przepływu — np. sekwencer–driver.
</details>

2. **Jak zbudujesz scoreboard dla bloku z wejściem i wyjściem o zmiennym opóźnieniu?**

<details>
<summary>Odpowiedź</summary>

Dwa wejścia (osobne monitory wejścia i wyjścia), model referencyjny liczący oczekiwany wynik z transakcji wejściowej, kolejka przewidywań i porównanie z transakcją wyjściową — w kolejności, a jeśli układ może zmieniać kolejność, wyszukiwanie po identyfikatorze. W `check_phase` sprawdzenie, czy kolejka jest pusta. Transakcje z monitorów przez `uvm_tlm_analysis_fifo`, przetwarzanie w `run_phase`.
</details>

### [11.06 — Konfiguracja: uvm_config_db, testy i środowiska](../modules/11-uvm/11.06-konfiguracja-uvm-config-db-testy-i-srodowiska.md)

1. **Jak przekazać wirtualny interfejs z modułu górnego do drivera?**

<details>
<summary>Odpowiedź</summary>

W module górnym, przed `run_test()`: `uvm_config_db #(virtual axil_if)::set(null, "uvm_test_top*", "vif", vif);` (albo tylko dla testu, który składa obiekt konfiguracji). Driver w `build_phase`: `if (!uvm_config_db #(virtual axil_if)::get(this, "", "vif", vif)) `uvm_fatal(…)`. W większych środowiskach `vif` trafia do obiektu konfiguracji agenta, który test przekazuje w dół jednym wpisem.
</details>

2. **Ustawiłeś wartość w `config_db`, a komponent jej nie widzi. Co sprawdzasz?**

<details>
<summary>Odpowiedź</summary>

Typ parametru w `set` i `get` (musi być identyczny), nazwę pola, ścieżkę względem kontekstu (`this` vs `null`, pełna nazwa komponentu, wzorzec `*`), kolejność faz (czy `set` wykonuje się przed `get`, np. w `build_phase` rodzica), wpisy o wyższym priorytecie nadpisujące wartość. Włączam śledzenie `config_db` i drukuję pełną nazwę komponentu (`get_full_name()`).
</details>

### [11.07 — Model rejestrów (RAL)](../modules/11-uvm/11.07-model-rejestrow-ral.md)

1. **Czym różnią się wartości pożądana, lustrzana i rzeczywista w RAL?**

<details>
<summary>Odpowiedź</summary>

Pożądana — to, co test chce zapisać (`set`, `randomize`), używana przez `update`. Lustrzana — najlepsza wiedza modelu o stanie układu, aktualizowana przez predyktor po każdej transakcji lub ręcznie `predict`. Rzeczywista — stan w układzie, odczytywany przez magistralę lub backdoor. `mirror(UVM_CHECK)` porównuje rzeczywistą z lustrzaną.
</details>

2. **Kiedy predykcja jawna (predyktor z monitora), a kiedy automatyczna?**

<details>
<summary>Odpowiedź</summary>

Automatyczna wystarcza, gdy jedynym masterem jest model rejestrów i układ nie zmienia rejestrów sam. Jawna jest potrzebna, gdy do rejestrów piszą też inne źródła (procesor, inne sekwencje, DMA), gdy test integracyjny używa tego samego modelu przy pasywnym agencie, i jest zalecana jako domyślna w środowiskach wielokrotnego użytku.
</details>

3. **Twój rejestr ma bit, który sprzęt ustawia przy błędzie i który kasuje się zapisem 1. Jak go zamodelujesz?**

<details>
<summary>Odpowiedź</summary>

Pole z dostępem `W1C`, `volatile = 1` (bo sprzęt je zmienia), wyłączone z bit-bash (`NO_REG_BIT_BASH_TEST`), a w testach — `predict(1)` po wywołaniu warunku błędu, potem `mirror(UVM_CHECK)` z włączonym porównaniem; zapis 1 i ponowne sprawdzenie, że predyktor i układ dają 0. Alternatywnie własny callback pola, który ustawia lustro na podstawie obserwowanego zdarzenia.
</details>

### [11.08 — Kompletny przykład: testbench UVM dla bloku z AXI4-Lite](../modules/11-uvm/11.08-kompletny-przyklad-testbench-uvm-dla-bloku-z.md)

1. **Opisz, jak zweryfikowałbyś blok z interfejsem rejestrowym AXI4-Lite w UVM.**

<details>
<summary>Odpowiedź</summary>

Plan: mapa rejestrów, dostęp i reset każdego pola, efekty uboczne, odpowiedzi błędu, protokół AXI. Środowisko: agent AXI4-Lite (driver z losowymi opóźnieniami i kolejnością AW/W, monitor odtwarzający transakcje, asercje handshake w interfejsie), model rejestrów generowany ze specyfikacji z adapterem i predyktorem z monitora, scoreboard z modelem funkcji bloku, pokrycie (rejestry × kierunek, WSTRB, odpowiedzi, kolejność kanałów). Testy: wbudowane sekwencje RAL (reset, bit-bash), testy funkcjonalne przez model rejestrów, losowy ruch, testy błędów (adresy spoza mapy), wiele ziaren; ocena testbencha wstrzykniętymi błędami; regresja w CI z pokryciem jako kryterium.
</details>

2. **Bit-bash przechodzi, a układ ma błąd w obsłudze WSTRB. Jak to możliwe?**

<details>
<summary>Odpowiedź</summary>

Wbudowane sekwencje RAL zapisują rejestry całymi słowami (wszystkie bajty włączone), więc ścieżka częściowego zapisu nie jest ćwiczona. Wykrywa to losowy ruch z różnymi WSTRB i scoreboard albo model rejestrów z polami dostępnymi bajtowo i adapterem przekazującym `byte_en`.
</details>

## 12 — Weryfikacja z otwartymi narzędziami

### [12.01 — cocotb: testbench w Pythonie](../modules/12-weryfikacja-open-source/12.01-cocotb-testbench-w-pythonie.md)

1. **Jak cocotb komunikuje się z symulatorem i jakie ma to konsekwencje dla szybkości?**

<details>
<summary>Odpowiedź</summary>

Przez standardowe interfejsy proceduralne symulatorów (VPI, VHPI, FLI): biblioteka cocotb ładowana do symulatora rejestruje wywołania zwrotne na zdarzenia i przekazuje sterowanie do interpretera Pythona. Każde przejście między symulatorem a Pythonem kosztuje, więc test z oczekiwaniem na każde zbocze jest wolniejszy niż testbench w HDL — opłaca się przy złożonych modelach i scenariuszach, a przy bardzo długich symulacjach przenosi się pobudzenia do HDL (np. bufory, BFM w HDL sterowane z Pythona transakcjami).
</details>

2. **Do czego służy `ReadOnly()`?**

<details>
<summary>Odpowiedź</summary>

Czeka na koniec bieżącego kroku czasu, gdy wszystkie przypisania (także nieblokujące i delta-cykle VHDL) są już wykonane. Odczyt w tej fazie daje stabilne, ostateczne wartości — np. wyjścia rejestrów po zboczu — niezależnie od kolejności procesów w symulatorze. Zapisy w tej fazie są zabronione.
</details>

### [12.02 — VUnit: testy jednostkowe dla VHDL i SystemVeriloga](../modules/12-weryfikacja-open-source/12.02-vunit-testy-jednostkowe-dla-vhdl-i.md)

1. **Co daje VUnit w porównaniu z własnym skryptem uruchamiającym GHDL?**

<details>
<summary>Odpowiedź</summary>

Automatyczne wyznaczanie kolejności kompilacji z zależności, kompilację przyrostową, wykrywanie testbenchy i przypadków testowych, izolację testów w osobnych symulacjach, równoległość, konfiguracje generików, raporty JUnit, obsługę wielu symulatorów jednym skryptem oraz biblioteki VHDL (asercje z komunikatami, logowanie, kolejki, komponenty weryfikacyjne).
</details>

2. **Jak przetestować ten sam testbench dla kilku wartości generika?**

<details>
<summary>Odpowiedź</summary>

W `run.py`: `tb.add_config(name=…, generics={…})` dla całego testbencha albo `tb.test("nazwa").add_config(…)` dla jednego przypadku. Każda konfiguracja to osobny test w raporcie, uruchamiany w osobnej symulacji.
</details>

### [12.03 — OSVVM i UVVM: metodologie dla VHDL](../modules/12-weryfikacja-open-source/12.03-osvvm-i-uvvm-metodologie-dla-vhdl.md)

1. **Czym jest pokrycie „inteligentne” w OSVVM?**

<details>
<summary>Odpowiedź</summary>

Model pokrycia służy jednocześnie do mierzenia i do generowania pobudzeń: `RandCovPoint` losuje wartość tylko z koszy, które nie osiągnęły jeszcze wymaganej liczby trafień (z uwzględnieniem wag). Pełne pokrycie osiąga się w liczbie transakcji bliskiej liczbie koszy, zamiast czekać, aż losowanie równomierne trafi rzadkie przypadki.
</details>

2. **Kiedy wybrałbyś UVVM, a kiedy OSVVM?**

<details>
<summary>Odpowiedź</summary>

UVVM — gdy zespół chce narzuconej architektury środowiska (VVC z kolejkami poleceń, rozdzielenie scenariusza od protokołu, dużo gotowych VVC), np. w większych projektach z wieloma interfejsami i wymaganiami certyfikacyjnymi. OSVVM — gdy liczy się prosty start, swoboda struktury i silne pokrycie funkcjonalne; również ma komponenty weryfikacyjne i raporty. Często decyduje to, co zespół już zna, i dostępność komponentów dla potrzebnych interfejsów.
</details>

### [12.04 — Verilator: szybka symulacja z C++](../modules/12-weryfikacja-open-source/12.04-verilator-szybka-symulacja-z-c.md)

1. **Czym Verilator różni się od symulatorów zdarzeniowych i jakie ma ograniczenia?**

<details>
<summary>Odpowiedź</summary>

Kompiluje HDL do C++ z harmonogramem wyznaczonym statycznie (z dynamicznym planowaniem dla konstrukcji czasowych od wersji 5), zamiast przetwarzać zdarzenia w czasie wykonania; jest przez to dużo szybszy. Ograniczenia: tylko Verilog/SystemVerilog, logika dwuwartościowa (brak `X`/`Z` jak w symulatorze czterowartościowym), ograniczona obsługa części konstrukcji niesyntezowalnych (choć wersja 5 obsługuje już opóźnienia, klasy, losowanie, a nawet UVM), czas kompilacji przy dużych projektach.
</details>

2. **Jak w testbenchu C++ zasymulować jeden takt zegara?**

<details>
<summary>Odpowiedź</summary>

Ustawić wejścia przy niskim zegarze i wywołać `eval()`, ustawić `clk = 1` i wywołać `eval()` (rejestry przyjmują wartości), odczytać wyjścia, opcjonalnie zapisać przebiegi `dump()` z czasem; przy kilku zegarach — kolejność zboczy według czasu, z `eval()` po każdej zmianie.
</details>

### [12.05 — Modele w Pythonie i porównanie bit w bit](../modules/12-weryfikacja-open-source/12.05-modele-w-pythonie-i-porownanie-bit-w-bit.md)

1. **Twój filtr w FPGA różni się od modelu MATLAB o 1 LSB w części próbek. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Sprawdzam, czy model jest dokładny co do bitu: czy odtwarza szerokości pośrednie, tryb zaokrąglenia (połówki w górę, do parzystej, obcięcie), kolejność zaokrąglenia i nasycenia, interpretację znaku i stan początkowy. Jeśli model odpowiada specyfikacji, różnica oznacza błąd układu (typowo obcięcie zamiast zaokrąglenia albo zaokrąglenie po złej stronie) — szukam pierwszej niezgodnej próbki i porównuję wartości pośrednie. Nie zwiększam tolerancji.
</details>

2. **Ile bitów potrzebuje akumulator filtru FIR o N współczynnikach?**

<details>
<summary>Odpowiedź</summary>

Szerokość iloczynu (bity wejścia + bity współczynnika) plus ⌈log₂ N⌉ na sumowanie w najgorszym przypadku; dokładniej — log₂ z sumy wartości bezwzględnych współczynników wyrażonej w jednostkach skali, co dla filtrów o małych współczynnikach pozwala na węższy akumulator. Dla `fir8`: 12 + 16 + 3 = 31 bitów.
</details>

### [12.06 — Ciągła integracja projektu HDL w GitHub Actions](../modules/12-weryfikacja-open-source/12.06-ciagla-integracja-projektu-hdl-w-github-actions.md)

1. **Jak zorganizowałbyś CI dla projektu FPGA z VHDL i SystemVerilogiem?**

<details>
<summary>Odpowiedź</summary>

Zadania równoległe: lint, symulacje jednostkowe (VUnit/cocotb, kilka symulatorów), testy systemowe, synteza open source dla szybkiej informacji zwrotnej, synteza i implementacja narzędziami producenta z analizą czasową na własnym runnerze, opcjonalnie testy na sprzęcie. Przypięte wersje narzędzi (kontenery albo paczki z datą), pamięć podręczna, raporty JUnit i pokrycia, artefakty (przebiegi z nieudanych testów, raporty czasowe), kryteria blokujące scalenie zmian. Dłuższe testy i wiele ziaren — w przebiegach nocnych.
</details>

2. **Test przechodzi lokalnie i nie przechodzi w CI. Gdzie szukasz przyczyny?**

<details>
<summary>Odpowiedź</summary>

Wersje narzędzi i pakietów (krok wypisujący wersje), różnice środowiska (zmienne, ścieżki, katalog roboczy, wielkość liter w nazwach plików), ziarno losowania, zależność od kolejności testów, limity czasu i zasobów (pamięć, liczba wątków), pliki generowane lokalnie i niezatwierdzone w repozytorium. Odtwarzam przebieg tym samym poleceniem i tymi samymi wersjami (np. w kontenerze).
</details>

## 13 — Weryfikacja formalna

### [13.01 — Dowód zamiast symulacji: BMC, indukcja i cover](../modules/13-weryfikacja-formalna/13.01-dowod-zamiast-symulacji-bmc-indukcja-i-cover.md)

1. **Czym różni się BMC od dowodu przez indukcję?**

<details>
<summary>Odpowiedź</summary>

BMC sprawdza wszystkie przebiegi o długości do *k* taktów od stanu początkowego — znajduje błędy płytsze niż *k*, ale nie mówi nic o dalszych taktach. Indukcja dodaje krok indukcyjny: z dowolnego stanu, w którym właściwość zachodzi przez *k* taktów, zachodzi też w następnym. Baza + krok = właściwość zachodzi zawsze. Krok indukcyjny może zawieść na stanie nieosiągalnym (CTI) — wtedy wynik jest nierozstrzygnięty, a nie błędny.
</details>

2. **Narzędzie zgłasza błąd kroku indukcyjnego, ale BMC na 50 taktów przechodzi. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Otwieram ślad indukcyjny i sprawdzam, czy stan startowy jest osiągalny z resetu. Jeśli nie (np. licznik poza zakresem, niespójne wskaźniki FIFO, automat w stanie, którego para z innym rejestrem jest niemożliwa) — dopisuję niezmiennik, który go wyklucza, i powtarzam. Jeśli stan jest osiągalny — to prawdziwy błąd, tylko głębszy niż 50 taktów; BMC z większą głębokością albo cover prowadzący do tego stanu go potwierdzi. Alternatywa: silnik PDR, który szuka niezmienników sam.
</details>

3. **Po co cover w weryfikacji formalnej, skoro asercje są dowodzone dla wszystkich wejść?**

<details>
<summary>Odpowiedź</summary>

Asercja „dla wszystkich wejść” obejmuje tylko wejścia dopuszczone przez założenia. Zbyt mocne lub sprzeczne założenia wykluczają ciekawe przebiegi i asercje przechodzą trywialnie (w skrajnym przypadku sprzeczne założenia = brak jakiegokolwiek przebiegu = wszystko „udowodnione”). Cover pokazuje, że przebiegi, których dotyczą asercje, są osiągalne, i daje gotowy ślad do obejrzenia.
</details>

4. **Czy weryfikacja formalna zastępuje symulację?**

<details>
<summary>Odpowiedź</summary>

Nie. Formalna jest najmocniejsza dla bloków sterujących, protokołów, arbitrów, kolejek i przypadków brzegowych, ograniczona rozmiarem układu i głębokością. Symulacja sprawdza cały system, długie scenariusze, wydajność, interakcję z oprogramowaniem i modelem odniesienia. W praktyce: formalnie bloki i interfejsy, symulacja — integracja i system; do tego formalne sprawdzanie równoważności po syntezie i zmianach.
</details>

### [13.02 — SymbiYosys: pierwsze dowody](../modules/13-weryfikacja-formalna/13.02-symbiyosys-pierwsze-dowody.md)

1. **Co zawiera plik .sby i jak uruchamiasz kilka wariantów tego samego dowodu?**

<details>
<summary>Odpowiedź</summary>

Sekcje: `[tasks]` (lista wariantów), `[options]` (tryb i głębokość), `[engines]` (silnik i solver), `[script]` (polecenia Yosysa wczytujące projekt, np. z definicjami preprocesora albo `chparam`), `[files]`. Linie poprzedzone `zadanie:` dotyczą jednego wariantu, więc jeden plik może zawierać BMC, dowód, cover i wersje z wstrzykniętymi błędami. `sby -f plik.sby zadanie` uruchamia jeden wariant, bez nazwy — wszystkie.
</details>

2. **Do czego służy `f_past_valid`?**

<details>
<summary>Odpowiedź</summary>

To rejestr równy 0 w pierwszym kroku i 1 później. W kroku 0 stan jest dowolny (poza wartościami początkowymi), a `$past` odnosi się do nieistniejącego taktu. `f_past_valid` pozwala założyć reset w pierwszym takcie i wyłączyć asercje, które w kroku 0 nie mają sensu. W kroku indukcyjnym jego wartość też jest dowolna, więc konstrukcje oparte na nim muszą działać dla obu wartości.
</details>

3. **Kiedy wybierzesz silnik `abc pdr` zamiast `smtbmc`?**

<details>
<summary>Odpowiedź</summary>

Gdy k-indukcja daje UNKNOWN, a ręczne szukanie niezmienników jest pracochłonne — PDR (IC3) buduje niezmienniki indukcyjne sam. Ograniczenia: pracuje na modelu bitowym (duże ścieżki danych i pamięci spowalniają go), nie daje kontrprzykładu indukcyjnego, który podpowiedziałby niezmiennik, i bywa wolniejszy. Często uruchamia się oba silniki równolegle.
</details>

### [13.03 — Pisanie właściwości: assume, assert, cover](../modules/13-weryfikacja-formalna/13.03-pisanie-wlasciwosci-assume-assert-cover.md)

1. **Czym różni się `assume` od `assert` i co się stanie, gdy założenia są sprzeczne?**

<details>
<summary>Odpowiedź</summary>

`assume` ogranicza zbiór rozważanych przebiegów (solver pomija te, w których założenie jest fałszywe), `assert` jest sprawdzane w przebiegach, które pozostały. Przy sprzecznych założeniach nie zostaje żaden przebieg — każda asercja jest „spełniona”, dowód nic nie znaczy. Wykrywa się to coverami: przy sprzecznych założeniach żaden cover nie jest osiągalny.
</details>

2. **Jak formalnie sprawdzić, że blok z interfejsem valid/ready nie gubi i nie nadpisuje danych?**

<details>
<summary>Odpowiedź</summary>

Założenia na wejściu: reset na starcie, wstrzymane `in_valid` z danymi stabilnymi do przyjęcia. Asercje na wyjściu: `out_valid && !out_ready` w takcie *t* ⇒ w takcie *t+1* `out_valid` i dane bez zmian (brak nadpisania i zniknięcia); wynik pojawia się po przyjęciu w określonym czasie; brak wyniku bez przyjęcia. Do tego asercja funkcji względem modelu odniesienia zapamiętanego przy przyjęciu i covery: wstrzymanie, pełna przepustowość. Dla bloków z kolejką — śledzenie dowolnego elementu (`anyconst`/`anyseq`) zamiast pełnego modelu.
</details>

3. **Co to jest assume-guarantee?**

<details>
<summary>Odpowiedź</summary>

Metoda dzielenia dowodu: blok A jest weryfikowany przy założeniach *P* na wejściach i dowodzi gwarancji *Q* na wyjściach; blok B, którego wejścia są wyjściami A, zakłada *Q*. Jeśli założenia każdego bloku są udowodnionymi gwarancjami sąsiada, połączenie jest poprawne bez weryfikowania całości naraz — a całość często jest za duża dla solvera.
</details>

### [13.04 — Formalna weryfikacja FIFO i interfejsów z handshakiem](../modules/13-weryfikacja-formalna/13.04-formalna-weryfikacja-fifo-i-interfejsow-z.md)

1. **Jak formalnie udowodnić, że FIFO nie gubi danych i zachowuje kolejność, bez modelowania całej zawartości?**

<details>
<summary>Odpowiedź</summary>

Śledzi się jeden element wybrany dowolnie przez solver (`anyseq`/`anyconst`): przy jego zapisie zapamiętuje się wskaźnik i wartość, a gdy wskaźnik odczytu do niego dojdzie i nastąpi odczyt — sprawdza się wartość. Skoro wychodzi dokładnie po wszystkich starszych i nienaruszony, a wybór był dowolny, właściwość zachodzi dla każdego elementu. Do pełnego dowodu indukcyjnego potrzebne są niezmienniki: licznik w zakresie, śledzony element między wskaźnikami, jego komórka nienadpisana. Wersja z dwoma elementami dowodzi kolejności bez odwoływania się do wskaźników.
</details>

2. **Jak rozpoznać FIFO pełne i puste przy wskaźnikach o jeden bit szerszych niż adres?**

<details>
<summary>Odpowiedź</summary>

Puste — wskaźniki identyczne. Pełne — młodsze bity (adres) równe, najstarszy różny: zapis wyprzedził odczyt o pełne okrążenie. Liczba elementów to różnica wskaźników modulo 2ⁿ⁺¹. Dodatkowy bit rozróżnia dwa przypadki, w których adresy są równe, bez osobnego licznika ani „marnowania” jednej komórki.
</details>

3. **Jakie reguły handshake valid/ready sprawdziłbyś formalnie dla nadawcy AXI-Stream?**

<details>
<summary>Odpowiedź</summary>

Po resecie `TVALID = 0`; raz podniesione `TVALID` pozostaje do przesłania (`TVALID && TREADY`); `TDATA`, `TLAST` i pozostałe pola stabilne, gdy `TVALID && !TREADY`; `TVALID` nie zależy od `TREADY` (nadawca nie może czekać na `TREADY`, by podnieść `TVALID`). Do tego covery: wstrzymanie, przesłania w kolejnych taktach, `TLAST`. Te same właściwości jako założenia służą do weryfikacji odbiorcy.
</details>

4. **Krok indukcyjny dla FIFO zawodzi, choć BMC na 30 taktów przechodzi. Od czego zaczynasz?**

<details>
<summary>Odpowiedź</summary>

Od śladu `trace_induct.vcd` i pytania, czy stan startowy jest osiągalny. Typowe przyczyny: licznik lub różnica wskaźników poza zakresem, flagi `full`/`empty` niespójne ze wskaźnikami (gdy są rejestrami, a nie funkcją wskaźników), śledzony element „poza kolejką” albo nadpisany w pamięci. Każdą dopisuję jako niezmiennik z uzasadnieniem. Gdy stan jest osiągalny — to prawdziwy błąd głębszy niż 30 taktów. Alternatywnie silnik PDR.
</details>

### [13.05 — Sprawdzanie równoważności i metody formalne w przemyśle](../modules/13-weryfikacja-formalna/13.05-sprawdzanie-rownowaznosci-i-metody-formalne-w.md)

1. **Czym jest sprawdzanie równoważności (LEC) i kiedy się je stosuje?**

<details>
<summary>Odpowiedź</summary>

Formalny dowód, że dwie reprezentacje układu mają identyczną funkcję dla wszystkich wejść. Stosuje się między RTL a netlistą po syntezie, po wstawieniu DFT, po optymalizacjach fizycznych i po ECO, a także między dwiema wersjami RTL po refaktoryzacji. Narzędzia dopasowują rejestry obu wersji i dowodzą równoważności logiki kombinacyjnej między nimi; gdy struktura stanów się zmienia (retiming, zmiana kodowania), potrzebne jest sprawdzanie sekwencyjne.
</details>

2. **Dlaczego retiming utrudnia LEC?**

<details>
<summary>Odpowiedź</summary>

Retiming przesuwa rejestry przez logikę kombinacyjną, więc rejestry netlisty nie odpowiadają już rejestrom RTL jeden do jednego, a logika między nimi jest inna. Klasyczny LEC oparty na dopasowaniu punktów nie znajduje par. Rozwiązania: sprawdzanie sekwencyjne (dowód równoważności na wyjściach przez wiele taktów), wyłączenie retimingu w przebiegu LEC, albo informacje o przesunięciach z narzędzia syntezy.
</details>

3. **Jakie zastosowania metod formalnych poza dowodzeniem asercji znasz?**

<details>
<summary>Odpowiedź</summary>

Sprawdzanie równoważności (kombinacyjnej i sekwencyjnej), łączność w SoC, weryfikacja mapy rejestrów, propagacja X, CDC/RDC, bezpieczeństwo (przepływ informacji), wykazywanie nieosiągalności koszy pokrycia kodu, generowanie przebiegów z coverów jako testów ukierunkowanych, *bug hunting* głębokim BMC od stanów z symulacji.
</details>

4. **Masz dwa układy kombinacyjne z 64 wejściami. Czemu nie wystarczy ich wysymulować?**

<details>
<summary>Odpowiedź</summary>

2⁶⁴ ≈ 1,8·10¹⁹ wektorów; przy 10⁹ wektorów na sekundę to ok. 580 lat. Losowa próbka nie daje dowodu, a różnica może występować dla jednej kombinacji. Miter + SAT rozwiązuje to symbolicznie — tu w ułamku sekundy — i albo dowodzi równoważności, albo podaje konkretny wektor różnicujący.
</details>

## 14 — Statyczna analiza czasowa (STA)

### [14.01 — Ścieżki czasowe, setup, hold i zapas (slack)](../modules/14-analiza-czasowa/14.01-sciezki-czasowe-setup-hold-i-zapas-slack.md)

1. **Wyprowadź warunek setup i hold dla ścieżki między dwoma przerzutnikami.**

<details>
<summary>Odpowiedź</summary>

Setup: dane wysłane zboczem w chwili 0 muszą dotrzeć przed następnym zboczem odbiornika minus t_su: t_co + t_komb,max ≤ T + skew − t_su. Hold: dane wysłane zboczem w chwili 0 nie mogą dotrzeć przed upływem t_h po tym samym zboczu w odbiorniku: t_co,min + t_komb,min ≥ skew + t_h. Skew = opóźnienie zegara do odbiornika minus do nadajnika; dodatni pomaga setup, szkodzi hold.
</details>

2. **Masz naruszenie hold. Czy obniżenie częstotliwości pomoże?**

<details>
<summary>Odpowiedź</summary>

Nie — w warunku hold nie ma okresu zegara. Naruszenie hold oznacza, że nowe dane docierają do odbiornika, zanim ten zdąży zapisać stare przy tym samym zboczu; zdarza się przy każdej częstotliwości. Naprawa: dłuższa ścieżka danych (narzędzie wstawia opóźnienie), mniejszy skew (zegar siecią globalną, nie przez logikę), poprawne ograniczenia interfejsu.
</details>

3. **Co to są WNS i TNS i do czego służą?**

<details>
<summary>Odpowiedź</summary>

WNS — najgorszy (najbardziej ujemny) zapas setup w projekcie: mówi, o ile trzeba skrócić najgorszą ścieżkę albo wydłużyć okres. TNS — suma ujemnych zapasów wszystkich punktów końcowych: mówi, jak powszechny jest problem (jedna ścieżka −0,5 ns i tysiąc ścieżek po −0,5 ns mają ten sam WNS, ale inny TNS i inną strategię naprawy). Odpowiedniki dla hold: WHS, THS.
</details>

4. **Dlaczego STA, a nie symulacja z opóźnieniami?**

<details>
<summary>Odpowiedź</summary>

STA sprawdza wszystkie ścieżki strukturalne we wszystkich narożnikach w sekundy i bez wektorów; symulacja z SDF tylko ścieżki pobudzone przez testbench, w jednym narożniku, bardzo wolno. Symulacja czasowa przydaje się do sprawdzenia, że ograniczenia (wyjątki) są poprawne, i do interfejsów asynchronicznych, których STA nie opisze.
</details>

### [14.02 — Zegar w praktyce: skew, jitter i niepewność](../modules/14-analiza-czasowa/14.02-zegar-w-praktyce-skew-jitter-i-niepewnosc.md)

1. **Czym różnią się skew i jitter i jak każde z nich wpływa na setup i hold?**

<details>
<summary>Odpowiedź</summary>

Skew to stała (dla danej pary przerzutników) różnica chwil przybycia tego samego zbocza; jitter to zmienność chwili zbocza w czasie (z okresu na okres). Skew dodatni (odbiornik później) zwiększa zapas setup i zmniejsza hold; jitter zmniejsza efektywny okres, więc odejmuje się od zapasu setup, a dla hold uwzględnia się tylko składnik, który może rozsunąć to samo zbocze w dwóch przerzutnikach. W SDC jitter i zapas projektowy zapisuje się jako `set_clock_uncertainty`.
</details>

2. **Co to jest CRPR i dlaczego jest potrzebne?**

<details>
<summary>Odpowiedź</summary>

Przy analizie z OCV ścieżka zegara nadajnika jest liczona jako późna, a odbiornika jako wczesna. Część drzewa zegara wspólna dla obu nie może jednocześnie mieć dwóch opóźnień, więc powstaje sztuczny pesymizm równy różnicy późnego i wczesnego opóźnienia wspólnej części. CRPR (*clock reconvergence pessimism removal*) go usuwa — w raporcie jako dodatnia poprawka zapasu.
</details>

3. **Dlaczego w FPGA nie używa się wyjścia licznika jako zegara?**

<details>
<summary>Odpowiedź</summary>

Sygnał z logiki nie jedzie siecią globalną — ma duży i zmienny skew względem zegara źródłowego, co powoduje naruszenia hold przy przesyłaniu danych między domenami. Narzędzie może go nie rozpoznać jako zegara (ścieżki nieograniczone) albo ostrzega o *ripple clock*. Poprawnie: jeden zegar i impuls zezwolenia co N taktów (taka sama funkcja, pełna analiza czasowa), albo PLL / blok sterowania zegarem, albo — gdy zegar musi wyjść z układu — `create_generated_clock` i staranne ograniczenia.
</details>

4. **Projekt przechodzi analizę w modelu Slow 85C, ale nie w Fast 0C. Jakiego rodzaju to błąd?**

<details>
<summary>Odpowiedź</summary>

Najprawdopodobniej hold — model szybki daje najkrótsze opóźnienia. Typowe przyczyny: interfejs zewnętrzny z błędnym `set_input_delay -min` / `set_output_delay -min`, zegar przez logikę z dużym skew, brakujący `-hold` przy ścieżce wielotaktowej. Rzadziej setup na ścieżce, której zegar odbiornika jest szybszy od danych w modelu szybkim.
</details>

### [14.03 — Ograniczenia SDC: zegary, zegary generowane, opóźnienia wejść i wyjść](../modules/14-analiza-czasowa/14.03-ograniczenia-sdc-zegary-zegary-generowane.md)

1. **Jak opiszesz wejście danych z zewnętrznego układu taktowanego tym samym zegarem co FPGA?**

<details>
<summary>Odpowiedź</summary>

Zegarem wirtualnym (albo zegarem portu, jeśli to ten sam sygnał) i `set_input_delay`: `-max` = t_co,max układu zewnętrznego + maksymalne opóźnienie ścieżki na płytce (z poprawką o różnicę opóźnień zegara do obu układów), `-min` = t_co,min + minimalne opóźnienie. Narzędzie dołoży opóźnienie wewnątrz FPGA i sprawdzi setup i hold przerzutnika wejściowego.
</details>

2. **Czym różni się `create_clock` od `create_generated_clock`?**

<details>
<summary>Odpowiedź</summary>

`create_clock` definiuje zegar pierwotny — źródło na porcie (albo wirtualne), z okresem i kształtem podanym wprost. `create_generated_clock` definiuje zegar pochodny od innego (`-source`): wyjście PLL, dzielnik w rejestrze, zegar przesłany na pin. Jego okres i faza wynikają z zegara nadrzędnego i parametrów (`-multiply_by`, `-divide_by`, `-edges`), a latencja — ze ścieżki od źródła, dzięki czemu narzędzie zna relację między zegarami.
</details>

3. **Kiedy użyjesz zegara wirtualnego?**

<details>
<summary>Odpowiedź</summary>

Gdy opisuje się wejścia lub wyjścia względem zegara, który nie wchodzi do FPGA tym pinem — zegar układu zewnętrznego, zegar z innym przesunięciem fazy niż zegar wewnętrzny, albo gdy chce się opisać interfejs niezależnie od tego, jak zegar trafia do FPGA (np. przez PLL z przesunięciem). Narzędzie analizuje wtedy relację między zegarem wirtualnym a zegarem przerzutnika w FPGA.
</details>

4. **Masz w projekcie zegary 50 MHz z oscylatora i 25 MHz odzyskany z PHY Ethernetu. Co wpisujesz do SDC?**

<details>
<summary>Odpowiedź</summary>

Dwa `create_clock` (oba porty), zegary generowane z PLL, jeśli są, i `set_clock_groups -asynchronous -group {zegary od 50 MHz} -group {zegary od 25 MHz PHY}`. Interfejs PHY opisany `set_input_delay`/`set_output_delay` względem zegara PHY. Przejścia danych między grupami — przez synchronizatory albo asynchroniczne FIFO, z ograniczeniami na opóźnienie (`set_max_delay -datapath_only` w Vivado, `set_net_delay`/`set_max_skew` w Quartusie) zamiast analizy synchronicznej.
</details>

### [14.04 — Wyjątki: false path, multicycle, max/min delay](../modules/14-analiza-czasowa/14.04-wyjatki-false-path-multicycle-max-min-delay.md)

1. **Napisz ograniczenia dla ścieżki, na której dane mają 3 takty, i wyjaśnij hold.**

<details>
<summary>Odpowiedź</summary>

`set_multicycle_path -setup 3 -from A -to B` i `set_multicycle_path -hold 2 -from A -to B`. Setup 3 przesuwa zbocze odbierające na 3·T. Domyślnie hold jest sprawdzany na zboczu o okres wcześniejszym niż zbocze setup, czyli na 2·T — wymagałoby to, by dane trzymały się przez 2 okresy po wysłaniu. `-hold 2` przesuwa zbocze hold o 2 okresy z powrotem, na 0, czyli zwykły warunek hold.
</details>

2. **Czym różni się `set_false_path` od `set_clock_groups -asynchronous`?**

<details>
<summary>Odpowiedź</summary>

`set_false_path` usuwa z analizy wskazane ścieżki (od/do/przez konkretne obiekty albo zegary) i działa w jedną stronę. `set_clock_groups -asynchronous` deklaruje relację między zegarami: wszystkie ścieżki między grupami, w obie strony, nie są analizowane, a narzędzie wie, że zegary są niezależne (w Vivado ma to też wpływ na analizę CDC i raporty). Do rozdzielenia domen używa się `set_clock_groups`; `set_false_path` — do pojedynczych ścieżek w obrębie domeny lub do portów.
</details>

3. **Kiedy multicycle jest niepoprawny, choć STA przechodzi?**

<details>
<summary>Odpowiedź</summary>

Gdy projekt nie gwarantuje założeń: rejestr źródłowy może zmienić się częściej niż co N taktów albo odbiornik zapisuje wynik w innym takcie niż N po zmianie (np. zezwolenie generowane z innego licznika, reset w środku, ścieżka objęta wzorcem przez pomyłkę). STA nie zna logiki sterującej — przyjmuje wyjątek na wiarę. Weryfikuje się to testem/asercją sprawdzającą stabilność danych i chwilę zapisu albo dowodem formalnym.
</details>

4. **Do czego służy `set_max_delay -datapath_only` w Vivado?**

<details>
<summary>Odpowiedź</summary>

Ogranicza opóźnienie samej ścieżki danych (bez skew zegarów i bez relacji między zegarami) — typowo na przejściach CDC, gdzie zegary są asynchroniczne, ale trzeba ograniczyć rozrzut opóźnień bitów (np. wskaźnik w kodzie Graya w asynchronicznym FIFO nie może się „rozjechać” o więcej niż okres). W Quartusie podobny efekt daje `set_max_delay`/`set_min_delay` z `set_net_delay` i `set_max_skew`.
</details>

### [14.05 — Czytanie raportów: Timing Analyzer i Vivado](../modules/14-analiza-czasowa/14.05-czytanie-raportow-timing-analyzer-i-vivado.md)

1. **Dostajesz projekt z ujemnym WNS. Od czego zaczynasz?**

<details>
<summary>Odpowiedź</summary>

Od sprawdzenia, czy liczba jest prawdziwa: ostrzeżenia przy czytaniu SDC, lista zegarów (okresy, zegary generowane), ścieżki nieograniczone, przejścia między zegarami — wiele naruszeń to brak `set_clock_groups` albo zegar domyślny. Potem podsumowanie na zegar i model, TNS i liczba naruszonych punktów końcowych, dopiero potem najgorsze ścieżki: relacja zboczy, poziomy logiki, udział połączeń, wachlarz wyjść, skew. Na tej podstawie decyzja: kod (potok), SDC (poprawny wyjątek), implementacja (rozmieszczenie, duplikacja).
</details>

2. **W raporcie ścieżki 75 % opóźnienia to połączenia, a logika ma 3 poziomy. Co robisz?**

<details>
<summary>Odpowiedź</summary>

To problem rozmieszczenia lub wachlarza, nie architektury. Sprawdzam fanout sieci na ścieżce (duży wachlarz → duplikacja rejestru, ograniczenie `max_fanout`, rejestr potoku przed rozgałęzieniem), położenie komórek (rozrzucone między odległymi blokami, np. DSP lub RAM na drugim końcu układu → rejestry przy granicach bloków, ograniczenia rozmieszczenia), czy ścieżka nie przechodzi przez blok I/O albo między regionami zegarowymi.
</details>

3. **Czym jest *Restricted Fmax* w Quartusie?**

<details>
<summary>Odpowiedź</summary>

f_max ograniczone nie tylko przez ścieżki rejestr–rejestr, ale też przez minimalną szerokość impulsu i maksymalną częstotliwość elementów, przez które przechodzi zegar (bloki pamięci, DSP, PLL, bufory I/O). Jeśli *Restricted Fmax* jest niższe od *Fmax*, ograniczeniem jest sprzęt, a nie logika.
</details>

### [14.06 — Ograniczenia interfejsów źródłowo-synchronicznych](../modules/14-analiza-czasowa/14.06-ograniczenia-interfejsow-zrodlowo.md)

1. **Czym różni się interfejs źródłowo-synchroniczny od systemowo-synchronicznego i dlaczego pozwala na wyższe częstotliwości?**

<details>
<summary>Odpowiedź</summary>

W systemowo-synchronicznym oba układy dostają zegar ze wspólnego źródła, więc budżet obejmuje t_co nadajnika, całe opóźnienie ścieżki danych na płytce i rozrzut zegara do obu układów. W źródłowo-synchronicznym nadajnik wysyła zegar razem z danymi tymi samymi typami ścieżek — opóźnienia płytki dla zegara i danych są prawie takie same i się znoszą; liczy się tylko ich różnica (skew), t_su i t_h odbiornika. Dlatego możliwe są setki MHz i transmisja DDR.
</details>

2. **Jak ograniczysz wyjście DDR z zegarem przesyłanym w Quartusie?**

<details>
<summary>Odpowiedź</summary>

Zegar wyjściowy jako `create_generated_clock` na porcie zegara (źródło: wyjście PLL zasilające rejestr DDR), dane: `set_output_delay -clock clk_out -max (t_su + skew_płytki)`, `-min (−t_h + skew)` dla zbocza narastającego oraz to samo z `-clock_fall -add_delay` dla opadającego. Do tego false path dla par zboczy, które nie przesyłają danych (np. dane wysłane na narastające analizowane względem opadającego, jeśli relacja jest inna niż zamierzona) — zgodnie z AN 433. Zegar i dane z rejestrów DDR w blokach I/O.
</details>

3. **Dlaczego przy odczycie SPI z zegarem z FPGA trzeba uwzględnić „pętlę”?**

<details>
<summary>Odpowiedź</summary>

Urządzenie zmienia MISO względem zbocza SCLK, które dotarło do niego po opóźnieniu wyjścia FPGA i ścieżki na płytce; MISO wraca kolejną ścieżką i przez bufor wejściowy, a FPGA próbkuje je zegarem wewnętrznym. Całość: t_zegar→pin + t_płytka + t_co + t_płytka + t_wejście musi zmieścić się w czasie między zboczem wysyłającym a próbkującym. W SDC: `set_input_delay` względem zegara generowanego na pinie SCLK (`-clock_fall` dla trybu 0), dzięki czemu narzędzie samo dolicza opóźnienie zegara wychodzącego.
</details>

4. **Dane wejściowe są wyrównane do krawędzi zegara. Jak je poprawnie próbkować?**

<details>
<summary>Odpowiedź</summary>

Przesunąć zegar próbkujący o około pół bitu: PLL z przesunięciem fazy 90° (SDR: 180°), linia opóźniająca (IDELAY, opóźnienie wejścia w bloku I/O) albo próbkowanie przeciwnym zboczem, jeśli okno na to pozwala. W SDC: zegar wchodzący jako `create_clock`, zegar PLL jako generowany z przesunięciem, `set_input_delay` w metodzie skew-based (±rozrzut) i ewentualne multicycle/false path dla relacji między przesuniętym a oryginalnym zboczem.
</details>

## 15 — Zegary, reset i przejścia między domenami (CDC)

### [15.01 — Generowanie zegarów: PLL, clock enable i dlaczego nie bramkować zegara](../modules/15-zegary-reset-cdc/15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md)

1. **Dlaczego w FPGA nie bramkuje się zegara bramką AND i co robi się zamiast tego?**

<details>
<summary>Odpowiedź</summary>

Bramka na zegarze daje szpilki i dodatkowe zbocza, gdy sygnał zezwolenia zmienia się przy wysokim stanie zegara (a zmienia się tuż po zboczu, bo pochodzi z przerzutnika), oraz wyprowadza zegar z sieci globalnej — duży skew, naruszenia hold i trudna analiza. Zamiast tego: zezwolenie zegara na wejściu `ENA` przerzutników (ta sama funkcja, jedna domena), a gdy trzeba naprawdę zatrzymać zegar dla oszczędności energii — dedykowany blok (ALTCLKCTRL, BUFGCE), który wyłącza sieć globalną bez szpilek.
</details>

2. **Jak działa komórka ICG?**

<details>
<summary>Odpowiedź</summary>

Zatrzask przezroczysty przy niskim stanie zegara przepuszcza zezwolenie tylko wtedy, gdy zegar jest niski; przy wysokim stanie trzyma ostatnią wartość. Iloczyn zegara i zatrzaśniętego zezwolenia zmienia się więc tylko razem ze zboczami zegara — bez szpilek. Wymaga, żeby zezwolenie ustaliło się przed narastającym zboczem (warunek czasowy jak setup), co sprawdza STA (*clock gating check*).
</details>

3. **Masz zegar 50 MHz i potrzebujesz logiki pracującej „z częstotliwością 1 kHz”. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Licznik w domenie 50 MHz generuje impuls o szerokości jednego taktu co 50 000 taktów, a logika „1 kHz” jest taktowana tym samym zegarem 50 MHz i zmienia stan tylko przy `if (tick)`. Jeśli ścieżki tej logiki są długie, można je opisać `set_multicycle_path` (gwarancja: zmiany co 50 000 taktów). Nie robię zegara 1 kHz z licznika.
</details>

### [15.02 — Metastabilność i MTBF — rachunek](../modules/15-zegary-reset-cdc/15.02-metastabilnosc-i-mtbf-rachunek.md)

1. **Co to jest metastabilność i czy synchronizator ją eliminuje?**

<details>
<summary>Odpowiedź</summary>

Stan przerzutnika, w którym po naruszeniu t_su/t_h wyjście przez nieokreślony czas nie jest poprawnym 0 ani 1. Nie da się jej wyeliminować dla sygnałów asynchronicznych; synchronizator daje dodatkowy czas (okres zegara na każdy stopień) na rozstrzygnięcie, przez co prawdopodobieństwo, że stan metastabilny dotrze do logiki, maleje wykładniczo — MTBF rośnie do tysięcy lat i więcej. Wartość po synchronizatorze jest poprawna, ale może pojawić się o takt później.
</details>

2. **Podaj wzór na MTBF i powiedz, który parametr ma największy wpływ.**

<details>
<summary>Odpowiedź</summary>

MTBF = exp(t_r/τ) / (T_w · f_clk · f_dane). Największy wpływ ma t_r — czas na ustalenie (w wykładniku): okres zegara docelowego minus t_co, t_su, połączenia i logika za przerzutnikiem. Dlatego zero logiki między stopniami, przerzutniki blisko siebie i dodatkowy stopień przy wysokich częstotliwościach. Częstotliwości zegara i danych wpływają tylko liniowo.
</details>

3. **Kiedy użyjesz trzech przerzutników zamiast dwóch?**

<details>
<summary>Odpowiedź</summary>

Gdy MTBF dwóch stopni jest niewystarczający: bardzo wysoka częstotliwość zegara docelowego (krótki okres = mało czasu na ustalenie), szybko zmieniający się sygnał, wymagania niezawodności (motoryzacja, medycyna, kosmos), duża liczba synchronizatorów lub urządzeń. Zalecenia producentów: Quartus raportuje MTBF i podpowiada liczbę stopni; AMD zaleca 2–3 w zależności od częstotliwości i wymagań.
</details>

### [15.03 — Synchronizatory jednobitowe i synchronizacja impulsów](../modules/15-zegary-reset-cdc/15.03-synchronizatory-jednobitowe-i-synchronizacja.md)

1. **Jak przesłać impuls jednego taktu z domeny 200 MHz do 25 MHz?**

<details>
<summary>Odpowiedź</summary>

Nie przez 2FF — impuls 5 ns zostanie zgubiony przez zegar 40 ns. Impuls zmienia stan przerzutnika (przełącznik) w domenie 200 MHz; poziom przechodzi przez synchronizator 2FF w domenie 25 MHz, a wykrycie zmiany (XOR z poprzednią wartością) daje jeden impuls 25 MHz. Jeśli impulsy mogą przyjść częściej niż co ok. 3 takty 25 MHz, potrzebne potwierdzenie z powrotem (blokada nadawcy) albo kolejka FIFO zdarzeń. Alternatywa dla rzadkich impulsów: rozciągnięcie do ≥ 1,5 okresu 25 MHz.
</details>

2. **Dlaczego wyjście pierwszego przerzutnika synchronizatora nie może iść do logiki?**

<details>
<summary>Odpowiedź</summary>

Pierwszy przerzutnik może być w stanie metastabilnym; jego wyjście ma wtedy napięcie pośrednie albo zmienia się z opóźnieniem. Różne bramki mogą odczytać je jako różne wartości (np. dwa przerzutniki automatu przejdą do niespójnych stanów), a czas ustalenia skrócony o logikę wykładniczo zmniejsza MTBF. Drugi przerzutnik daje pełny okres na rozstrzygnięcie i jedną, spójną wartość dla całej logiki.
</details>

3. **Co to jest reguła trzech zboczy?**

<details>
<summary>Odpowiedź</summary>

Sygnał przechodzący przez synchronizator do wolniejszej domeny powinien być stabilny przez co najmniej trzy kolejne zbocza zegara docelowego (ok. 1,5 okresu lub więcej z zapasem na jitter i rozrzut), żeby na pewno został zarejestrowany mimo możliwego naruszenia t_su/t_h na pierwszym zboczu. Krótsze impulsy trzeba rozciągnąć albo przesłać jako przełącznik.
</details>

### [15.04 — Przesyłanie słów: handshake, kod Graya i MCP](../modules/15-zegary-reset-cdc/15.04-przesylanie-slow-handshake-kod-graya-i-mcp.md)

1. **Jak przesłać 32-bitowe słowo między dwiema asynchronicznymi domenami?**

<details>
<summary>Odpowiedź</summary>

Nie bit po bicie. Dla pojedynczych słów: handshake/MCP — słowo w rejestrze nadawcy trzymane stałe, do odbiorcy przez synchronizator przechodzi tylko sygnał sterujący (zmiana `req`), po jego dotarciu odbiorca zapisuje słowo i odsyła potwierdzenie; ścieżka danych ograniczona w SDC maksymalnym opóźnieniem. Dla strumienia słów: asynchroniczna kolejka FIFO. Dla wartości zmieniających się o 1 (liczniki) — kod Graya z synchronizatorem na każdy bit.
</details>

2. **Dlaczego kod Graya jest bezpieczny przy synchronizacji bit po bicie i jakie ma ograniczenia?**

<details>
<summary>Odpowiedź</summary>

Kolejne wartości różnią się jednym bitem, więc w chwili próbkowania niepewny jest tylko jeden bit — odbiornik dostaje starą albo nową wartość. Ograniczenia: wartość może zmieniać się tylko o ±1 na takt nadawcy, kod musi być w rejestrze (nie z logiki), rozrzut opóźnień bitów do synchronizatora musi być mniejszy niż okres nadawcy, a licznik powinien obejmować pełny zakres 2ⁿ. Nie nadaje się do dowolnych danych.
</details>

3. **Czym różni się protokół handshake dwufazowy od czterofazowego?**

<details>
<summary>Odpowiedź</summary>

W dwufazowym każda zmiana poziomu `req` (0→1 albo 1→0) oznacza nowe słowo, a `ack` odbija tę zmianę — jedna podróż tam i z powrotem na słowo. W czterofazowym `req` idzie na 1, odbiorca odpowiada `ack` = 1, nadawca zdejmuje `req`, odbiorca zdejmuje `ack` — dwie podróże na słowo, ale sygnały są poziomami „aktywny/nieaktywny”, łatwiejsze do zrozumienia i odporne na zgubienie stanu po resecie jednej strony. Dwufazowy jest dwa razy szybszy.
</details>

### [15.05 — Asynchroniczna kolejka FIFO](../modules/15-zegary-reset-cdc/15.05-asynchroniczna-kolejka-fifo.md)

1. **Zaprojektuj asynchroniczną kolejkę FIFO. Jak liczysz flagi pełna i pusta?**

<details>
<summary>Odpowiedź</summary>

Pamięć dwuportowa, wskaźniki zapisu i odczytu o jeden bit szersze niż adres, każdy w postaci binarnej (adres) i Graya (rejestr). Gray wskaźnika zapisu przez synchronizator 2FF do domeny odczytu, Gray odczytu — do domeny zapisu. Pusta w domenie odczytu: następny Gray odczytu równy zsynchronizowanemu Grayowi zapisu. Pełna w domenie zapisu: następny Gray zapisu równy zsynchronizowanemu Grayowi odczytu z odwróconymi dwoma najstarszymi bitami. Flagi rejestrowane, liczone z wartości następnych.
</details>

2. **Dlaczego flagi asynchronicznego FIFO są „pesymistyczne” i czy to problem?**

<details>
<summary>Odpowiedź</summary>

Każda domena widzi wskaźnik drugiej z opóźnieniem synchronizatora, czyli starszą wartość. Zapisujący widzi mniej odczytów — kolejka wygląda na pełniejszą; czytający widzi mniej zapisów — wygląda na pustszą. Flaga może więc trwać o 2–3 takty dłużej niż trzeba, ale nigdy nie dopuści przepełnienia ani odczytu z pustej. Kosztem jest nieco mniejsza efektywna głębokość i przepustowość przy krótkich kolejkach — uwzględnia się to w doborze głębokości.
</details>

3. **Jak dobrać głębokość FIFO między domeną 100 MHz a 75 MHz dla paczek po 256 słów?**

<details>
<summary>Odpowiedź</summary>

W czasie paczki (256 taktów 100 MHz = 2,56 µs) odbiorca odczyta 2,56 µs · 75 MHz = 192 słowa, więc w kolejce zbierze się 64 słowa; do tego zapas na opóźnienie flag i synchronizacji (kilka słów) i ewentualne przerwy w odczycie. Głębokość 64 + ~8 → zaokrąglona do potęgi dwójki: 128. Warunek: średnio odbiorca musi nadążać — przerwy między paczkami ≥ czas opróżnienia.
</details>

4. **Dlaczego wskaźniki mają o jeden bit więcej niż adres?**

<details>
<summary>Odpowiedź</summary>

Żeby odróżnić kolejkę pełną od pustej: w obu przypadkach adresy (młodsze bity) są równe. Dodatkowy bit liczy okrążenia — równe wszystkie bity = pusta, różny tylko najstarszy (w binarnym) = pełna. Alternatywą jest osobny licznik zajętości, którego w FIFO asynchronicznym nie da się łatwo utrzymać w dwóch domenach.
</details>

### [15.06 — Strategie resetu: synchronizator resetu i RDC](../modules/15-zegary-reset-cdc/15.06-strategie-resetu-synchronizator-resetu-i-rdc.md)

1. **Narysuj synchronizator resetu i wyjaśnij, dlaczego reset jest „asynchronicznie ustawiany, synchronicznie zdejmowany”.**

<details>
<summary>Odpowiedź</summary>

Dwa przerzutniki z asynchronicznym zerowaniem od zewnętrznego resetu; wejście D pierwszego na stałe 1, wyjście drugiego to reset domeny. Ustawienie natychmiastowe (bez zegara) — układ przechodzi w bezpieczny stan nawet bez zegara. Zdjęcie: jedynka przechodzi przez dwa przerzutniki taktowane zegarem domeny, więc wszystkie przerzutniki domeny widzą koniec resetu na tym samym zboczu, z czasem ustalenia sprawdzanym przez STA (recovery/removal), a ewentualna metastabilność pierwszego stopnia ma pełny okres na rozstrzygnięcie.
</details>

2. **Czym jest RDC i czym różni się od CDC?**

<details>
<summary>Odpowiedź</summary>

RDC (*reset domain crossing*) to ścieżka z przerzutnika w jednej domenie resetu do przerzutnika w innej — nawet w tej samej domenie zegarowej. Gdy źródło jest resetowane asynchronicznie, a odbiornik nie, zmiana stanu źródła następuje w dowolnej chwili względem zegara odbiornika — możliwa metastabilność, jak przy CDC. Rozwiązania: wspólny reset, kolejność (odbiornik w reset przed źródłem), izolacja wyjścia domeny resetowanej, reset synchroniczny.
</details>

3. **Czy każdy przerzutnik w FPGA potrzebuje resetu?**

<details>
<summary>Odpowiedź</summary>

Nie. Wartość po konfiguracji jest znana z bitstreamu. Reset potrzebują elementy sterujące, które muszą wrócić do stanu początkowego w trakcie pracy (automaty, liczniki, flagi, wskaźniki, sygnały valid). Rejestry danych nie potrzebują — ich zawartość jest ignorowana, dopóki valid = 0. Mniej resetu oznacza mniejszy wachlarz, lepsze zamknięcie czasu i możliwość wchłonięcia rejestrów przez bloki DSP i RAM.
</details>

### [15.07 — Ograniczenia i weryfikacja CDC](../modules/15-zegary-reset-cdc/15.07-ograniczenia-i-weryfikacja-cdc.md)

1. **Jak ograniczyłbyś w SDC/XDC wskaźniki Graya asynchronicznej kolejki FIFO?**

<details>
<summary>Odpowiedź</summary>

Nie samą grupą asynchroniczną, bo wyłącza ona analizę. W Vivado: `set_max_delay -datapath_only` z rejestru wskaźnika do pierwszego stopnia synchronizatora o wartości ok. okresu zegara nadajnika (często mniej) oraz `set_bus_skew` dla bitów wskaźnika — i bez `set_clock_groups` na tej parze zegarów, bo ma ona pierwszeństwo. W Quartusie: grupy mogą zostać, a `set_net_delay -max` i `set_max_skew` na wskaźnikach działają niezależnie (tak ograniczony jest `dcfifo`). Cel: każdy bit dociera przed następną zmianą wskaźnika, więc odbiornik widzi tylko kolejne wartości kodu Graya.
</details>

2. **Dlaczego STA bez ograniczeń zgłasza błąd na ścieżce między niezależnymi zegarami, i dlaczego ten wynik jest bez znaczenia?**

<details>
<summary>Odpowiedź</summary>

STA zakłada, że zegary mają stałą relację fazową, rozwija je do wspólnej wielokrotności okresów i wybiera najciaśniejszą parę zboczy nadania i odbioru. Dla 10 ns i 27,3 ns jest to para różniąca się o 0,1 ns — wymaganie niemożliwe do spełnienia. Ponieważ zegary są w rzeczywistości niezależne, każda relacja faz wystąpi i układ musi to tolerować (synchronizator, protokół), a nie spełnić setup względem konkretnej pary zboczy. Zamiast tej analizy ogranicza się samo opóźnienie i rozrzut.
</details>

3. **Czego nie wykryje narzędzie CDC (analiza strukturalna)?**

<details>
<summary>Odpowiedź</summary>

Błędów protokołu: czy dane przy handshake'u są naprawdę stabilne, gdy odbiornik je przechwytuje; czy impuls nie jest za krótki dla synchronizatora; czy kod jest naprawdę kodem Graya (jeśli nie sprawdza tego formalnie); czy kolejność resetu jest dobra; problemów reconvergence (kilka niezależnie zsynchronizowanych sygnałów łączonych później w logice — każdy może dojść o takt wcześniej). Do tego służą testy z losowymi fazami zegarów, asercje i dowody formalne.
</details>

4. **Co to jest reconvergence w CDC?**

<details>
<summary>Odpowiedź</summary>

Dwa lub więcej sygnałów z jednej domeny synchronizowanych osobno, a potem łączonych w logice drugiej domeny. Każdy synchronizator może dodać takt opóźnienia niezależnie, więc w domenie odbiornika przez takt widać kombinację, która w nadajniku nigdy nie wystąpiła. Rozwiązania: przesyłać je jako jedno słowo (handshake, Gray, FIFO) albo zaprojektować odbiornik odporny na różnicę jednego taktu.
</details>

## 16 — Wydajność, zasoby i pobór mocy

### [16.01 — Potokowanie i retiming](../modules/16-wydajnosc-zasoby-moc/16.01-potokowanie-i-retiming.md)

1. **Ścieżka ma 12 ns, zegar 100 MHz. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Najpierw sprawdzam, z czego się składa (logika czy połączenia, ile poziomów) i czy to ścieżka rzeczywista (może wielotaktowa albo fałszywa). Jeśli logika: potokuję — rejestr w miejscu, które dzieli opóźnienie mniej więcej na pół, i przesunięcie sygnału ważności o takt. Jeśli latencja jest zablokowana — restrukturyzacja logiki (drzewo zamiast łańcucha, przeniesienie decyzji wcześniej), retiming narzędzia. Jeśli połączenia — rozmieszczenie lub rejestr w połowie drogi.
</details>

2. **Czym różni się potokowanie od retimingu?**

<details>
<summary>Odpowiedź</summary>

Potokowanie dodaje rejestry i zwiększa latencję; robi to projektant (zmienia zachowanie cyklowe układu). Retiming przesuwa istniejące rejestry przez logikę bez zmiany liczby rejestrów na ścieżkach, więc bez zmiany latencji i funkcji; robi to narzędzie. W praktyce łączy się oba: projektant dodaje rejestry na wyjściu bloku, a retiming rozmieszcza je wewnątrz.
</details>

3. **Dlaczego nie da się po prostu dodać rejestru do akumulatora, żeby był szybszy?**

<details>
<summary>Odpowiedź</summary>

Akumulator to pętla: suma z bieżącego taktu jest argumentem w następnym. Rejestr w pętli sprawia, że do wejścia dodawana jest suma sprzed dwóch taktów — powstają dwa przeplecione akumulatory (każdy sumuje co drugą próbkę). Można to wykorzystać: dwie sumy częściowe i dodanie ich na końcu, albo przeplot dwóch niezależnych strumieni (C-slow), ale wymaga to zmiany algorytmu.
</details>

### [16.02 — Współdzielenie zasobów i kompromis powierzchnia–szybkość](../modules/16-wydajnosc-zasoby-moc/16.02-wspoldzielenie-zasobow-i-kompromis.md)

1. **Masz 10 wolnych mnożarek, a filtr potrzebuje 32 mnożeń na próbkę przy próbkowaniu 10 MHz i zegarze 200 MHz. Czy się zmieści?**

<details>
<summary>Odpowiedź</summary>

Potrzeba 32 · 10 MHz = 320 mln mnożeń/s; jedna mnożarka przy 200 MHz wykonuje 200 mln/s, więc wystarczą ⌈320/200⌉ = 2 mnożarki ze współdzieleniem w czasie (każda wykonuje 16 mnożeń na próbkę w 20 taktach dostępnych na próbkę). Mieści się z zapasem; koszt to multipleksery współczynników i próbek (albo pamięć), akumulatory i sterowanie.
</details>

2. **Czy synteza sama połączy dwie mnożarki w `y = sel ? a*b : c*d`?**

<details>
<summary>Odpowiedź</summary>

Często tak — narzędzia mają współdzielenie zasobów dla operacji wzajemnie się wykluczających (Quartus: *Auto Resource Sharing*, Vivado: `-resource_sharing`, Yosys: przebieg `share`). Ale zależy to od ustawień, przebiegu i struktury kodu (np. czy mnożenia są w tym samym bloku, czy wynik idzie przez rejestr). W eksperymencie z modułu ten sam Yosys połączył mnożarki w syntezie ECP5, a w syntezie ogólnej nie. Jeśli zasób jest krytyczny, współdzieli się ręcznie i sprawdza w raporcie.
</details>

3. **Kiedy powielisz zasób zamiast go współdzielić?**

<details>
<summary>Odpowiedź</summary>

Gdy przepustowość przy dostępnej częstotliwości wymaga więcej operacji na takt, niż daje jeden zasób, albo gdy zegar nie może być wyższy (ograniczenie układu, mocy, interfejsu). Dwie kopie przy połowie częstotliwości dają tę samą przepustowość co jedna przy pełnej, a łatwiej zamykają timing — kosztem powierzchni.
</details>

### [16.03 — Fanout, duplikacja rejestrów i głębokość logiki](../modules/16-wydajnosc-zasoby-moc/16.03-fanout-duplikacja-rejestrow-i-glebokosc-logiki.md)

1. **Jak zredukujesz fanout sygnału, który steruje 2000 przerzutników?**

<details>
<summary>Odpowiedź</summary>

Najpierw sprawdzam, czy to problem (raport: udział połączeń na ścieżce). Jeśli tak: ograniczenie fanoutu w narzędziu (`MAX_FANOUT`, `maxfan`) albo fizyczna synteza z duplikacją, ewentualnie ręczne kopie rejestru źródłowego z atrybutem `dont_merge`/`DONT_TOUCH` — każda kopia przy swojej grupie odbiorców; przy bardzo dużych wachlarzach drzewo rejestrów (takt opóźnienia); dla wolno zmieniających się sygnałów — sieć globalna. Jeśli to reset — ograniczam liczbę resetowanych rejestrów.
</details>

2. **Dlaczego synteza usuwa twoje zduplikowane rejestry i jak temu zapobiec?**

<details>
<summary>Odpowiedź</summary>

Rejestry z tym samym wejściem, zegarem i sterowaniem są logicznie równoważne — scalenie oszczędza zasoby, więc to standardowa optymalizacja. Zapobiega jej atrybut na rejestrach: Quartus `dont_merge` lub `preserve`, Vivado `DONT_TOUCH` (albo `MAX_FANOUT`, które powoduje duplikację kontrolowaną przez narzędzie). W eksperymencie z modułu Yosys scalił 32 kopie w jedną, bo nie interpretuje tych atrybutów jako zakazu scalania.
</details>

3. **Ścieżka przechodzi przez 15 poziomów logiki. Co sprawdzasz w kodzie?**

<details>
<summary>Odpowiedź</summary>

Czy to łańcuch operacji łącznych (przebudowa w drzewo), łańcuch priorytetowy `if/else if` (równoległy wybór), porównanie licznika w ścieżce (flaga liczona takt wcześniej), dekodowanie stanu binarnego (jednogorące), późny sygnał na początku logiki (przesunięcie na koniec). Jeśli struktura jest już optymalna — potok ([16.01](../modules/16-wydajnosc-zasoby-moc/16.01-potokowanie-i-retiming.md)).
</details>

### [16.04 — Zamykanie timingu: metodyka krok po kroku](../modules/16-wydajnosc-zasoby-moc/16.04-zamykanie-timingu-metodyka-krok-po-kroku.md)

1. **Projekt nie spełnia wymagań czasowych o 0,5 ns. Opisz, co robisz po kolei.**

<details>
<summary>Odpowiedź</summary>

Sprawdzam ograniczenia (zegary, niepewność, ścieżki nieograniczone, wyjątki) i czy najgorsza ścieżka jest rzeczywista. Potem diagnozuję kilka najgorszych ścieżek: poziomy logiki, udział połączeń, fanout, skew, czy to przejście między domenami. Poprawiam przyczynę w RTL — potok, restrukturyzacja, duplikacja, rejestry DSP/RAM. Dopiero jeśli brakuje niewiele przy zamrożonym RTL: ustawienia Fittera (wysiłek, fizyczna synteza), rozmieszczenie obszarami i przegląd ziaren. Po każdej zmianie sprawdzam setup i hold we wszystkich narożnikach.
</details>

2. **Czy przegląd ziaren to dobra metoda zamknięcia timingu?**

<details>
<summary>Odpowiedź</summary>

Jako ostatni krok przy zamrożonym projekcie i małym brakującym zapasie — tak. Jako metoda podstawowa — nie: wynik jest losowy, a projekt zamykany przypadkowym ziarnem traci margines przy każdej zmianie. Rozrzut f_max między ziarnami (w przykładzie z modułu 8,9 %) pokazuje też, że porównując dwie wersje RTL, trzeba porównywać kilka kompilacji, a nie jedną.
</details>

3. **Ścieżka ma 3 poziomy logiki, a 70 % jej opóźnienia to połączenia. Co to oznacza?**

<details>
<summary>Odpowiedź</summary>

Logika nie jest problemem — problemem jest odległość albo przeciążenie trasowania. Sprawdzam fanout sygnałów na ścieżce (duplikacja), położenie źródła i celu w Chip Plannerze/Device View (może łączą odległe bloki lub piny), zajętość układu i przeciążenie. Poprawki: duplikacja rejestru blisko odbiorców, rejestr w połowie drogi, ograniczenie obszaru dla powiązanych bloków, zmniejszenie zajętości.
</details>

### [16.05 — Floorplanning i ograniczenia fizyczne](../modules/16-wydajnosc-zasoby-moc/16.05-floorplanning-i-ograniczenia-fizyczne.md)

1. **Kiedy użyłbyś Logic Lock/Pblocka?**

<details>
<summary>Odpowiedź</summary>

Gdy narzędzie bez wiedzy o systemie rozmieszcza blok źle: interfejs musi być przy swoich pinach lub bankach pamięci, blok intensywnie korzysta z konkretnej kolumny DSP/RAM, dwa bloki są silnie połączone, a narzędzie je rozrywa; przy kompilacji przyrostowej i partycjach (powtarzalność wyników); w układach wieloczęściowych (SLR). Nie używałbym na start ani dla pojedynczych ścieżek — najpierw rozmieszczenie automatyczne i jego analiza.
</details>

2. **Ścieżka rejestr–rejestr bez logiki nie spełnia wymagań. Co to oznacza i co robisz?**

<details>
<summary>Odpowiedź</summary>

Całe opóźnienie to połączenie — źródło i cel są daleko od siebie (albo trasowanie jest przeciążone, albo duży skew zegara). Sprawdzam położenie obu rejestrów i dlaczego narzędzie je rozsunęło (inne połączenia, piny, bloki twarde). Rozwiązania: rejestr w połowie drogi (potok połączenia), duplikacja źródła bliżej odbiorców, obszar przybliżający oba końce, rejestr w buforze I/O, jeśli to ścieżka z pinu.
</details>

### [16.06 — Pobór mocy: statyczny i dynamiczny, szacowanie i redukcja](../modules/16-wydajnosc-zasoby-moc/16.06-pobor-mocy-statyczny-i-dynamiczny-szacowanie-i.md)

1. **Z czego składa się moc FPGA i od czego zależy każda część?**

<details>
<summary>Odpowiedź</summary>

Statyczna — upływ tranzystorów: rozmiar układu, proces, napięcie, temperatura złącza; prawie niezależna od projektu. Dynamiczna rdzenia — ½·α·C·V²·f dla każdej sieci: aktywność (dane, kodowanie, szpilki), pojemność (długość połączeń, fanout), napięcie, częstotliwość; plus zegary i bloki twarde. I/O — standardy, napięcia, prądy, terminacja, obciążenie i częstotliwość przełączania na pinach.
</details>

2. **Jak zmniejszysz moc dynamiczną bez zmiany funkcji?**

<details>
<summary>Odpowiedź</summary>

Ograniczam przełączanie bez potrzeby: clock enable i izolacja argumentów (bloki nie liczą na śmieciach), wyłączanie zegara całych bloków przez dedykowane bufory z zezwoleniem, kodowanie o małej aktywności (Gray), rejestry przed szerokim rozgałęzieniem przeciw szpilkom, zezwolenia w blokach RAM. Dalej: niższa częstotliwość z większą równoległością, niższe napięcia I/O, wyłączenie nieużywanych PLL i bloków. Skutek sprawdzam Power Analyzerem z aktywnością z symulacji.
</details>

3. **Skąd Power Analyzer bierze aktywność sygnałów i jak to wpływa na wynik?**

<details>
<summary>Odpowiedź</summary>

Z plików symulacji (VCD/SAIF) — najdokładniej z symulacji netlisty po rozmieszczeniu, z opóźnieniami; z szacowania bez wektorów — propagacja prawdopodobieństw od wejść, dla których podano aktywność; albo z wartości domyślnych (w Quartusie 12,5 %). Wynik może się różnić kilkukrotnie; dlatego raport podaje pewność szacowania, a dla zasilacza dodaje się zapas albo mierzy prąd na płytce.
</details>

## 17 — Uruchamianie i debug na sprzęcie

### [17.01 — Strategia uruchamiania: od diody do analizatora logicznego](../modules/17-debug-na-sprzecie/17.01-strategia-uruchamiania-od-diody-do-analizatora.md)

1. **Dostajesz nową płytkę z FPGA i gotowy projekt, który „nie działa”. Od czego zaczniesz?**

<details>
<summary>Odpowiedź</summary>

Od rzeczy najprostszych i niezależnych od projektu: zasilanie (napięcia, prąd), zegar (oscylator, pomiar), łańcuch JTAG (czy układ jest widoczny), konfiguracja (czy bitstream się wgrywa i układ startuje). Potem najprostszy projekt: dioda migająca z każdego zegara, echo przycisków, stan PLL, pomiar częstotliwości. Dopiero gdy fundament jest pewny, uruchamiam bloki projektu po kolei, używając wbudowanych liczników, flag i analizatora logicznego.
</details>

2. **Co wbudujesz w projekt, żeby łatwiej go debugować na sprzęcie?**

<details>
<summary>Odpowiedź</summary>

Bicie serca w każdej domenie zegarowej, rejestr wersji, liczniki zdarzeń i błędów, flagi lepkie dla błędów przejściowych, rejestry statusu odczytywane przez JTAG (ISSP, mostek JTAG-to-Avalon/AXI) albo interfejs szeregowy, pętle zwrotne interfejsów, kilka pinów testowych z multiplekserem sygnałów wewnętrznych i miejsce (pamięć, logika) na wbudowany analizator.
</details>

3. **Jak sprawdzisz, że PLL daje właściwą częstotliwość, bez oscyloskopu?**

<details>
<summary>Odpowiedź</summary>

Miernikiem częstotliwości w układzie: licznik taktów zegara PLL w oknie odmierzanym znanym zegarem (np. oscylatorem 50 MHz), z przejściem między domenami przez kod Graya i synchronizator. Wynik odczytuję przez JTAG (In-System Sources and Probes) albo pokazuję na diodach. Dokładność: ±1 takt na okno plus dokładność oscylatora odniesienia.
</details>

### [17.02 — Wbudowany analizator logiczny: Signal Tap i ILA](../modules/17-debug-na-sprzecie/17.02-wbudowany-analizator-logiczny-signal-tap-i-ila.md)

1. **Jak działa Signal Tap/ILA i ile kosztuje?**

<details>
<summary>Odpowiedź</summary>

Wbudowany w projekt rdzeń: wybrane sygnały są zapisywane w każdym takcie wybranego zegara do bufora kołowego w blokach RAM układu; komparatory sprawdzają warunek wyzwolenia; po wyzwoleniu zapisywana jest jeszcze ustalona liczba próbek, a bufor jest odczytywany przez JTAG i wyświetlany jako przebiegi. Koszt: pamięć (głębokość × liczba sygnałów), logika wyzwalania i hub JTAG, dodatkowe obciążenie badanych sygnałów, ponowna kompilacja przy zmianie sond i możliwa zmiana rozmieszczenia (wpływ na timing).
</details>

2. **Sygnał, który chcesz obejrzeć, nie pojawia się w Node Finderze. Dlaczego?**

<details>
<summary>Odpowiedź</summary>

Synteza go usunęła lub połączyła z innym (stała, logika zoptymalizowana, rejestr zduplikowany/scalony, sygnał wewnątrz bloku DSP lub RAM). Rozwiązania: atrybut zachowania (`keep` dla sieci, `preserve`/`noprune` dla rejestrów w Quartusie, `MARK_DEBUG` w Vivado), wybór odpowiedniego węzła po rozmieszczeniu albo wyprowadzenie sygnału do rejestru, który na pewno zostanie.
</details>

3. **Błąd występuje raz na kilka minut. Jak go złapać wbudowanym analizatorem?**

<details>
<summary>Odpowiedź</summary>

Wyzwolenie na objawie (flaga błędu, licznik błędów, nieoczekiwany stan automatu) z dużą liczbą próbek przed wyzwoleniem, żeby zobaczyć przyczynę; jeśli przyczyna jest dużo wcześniej — kwalifikator zapisu (zapis tylko istotnych próbek, np. transakcji) albo bufor segmentowy, wyzwolenie sekwencyjne (najpierw warunek A, potem B), tryb ciągły z automatycznym ponawianiem. Do tego flaga lepka w projekcie, żeby wiedzieć, że błąd w ogóle wystąpił.
</details>

### [17.03 — In-System Sources and Probes, VIO i JTAG-to-Avalon](../modules/17-debug-na-sprzecie/17.03-in-system-sources-and-probes-vio-i-jtag-to.md)

1. **Do czego służy In-System Sources and Probes (VIO) i czym różni się od Signal Tap (ILA)?**

<details>
<summary>Odpowiedź</summary>

ISSP/VIO to wirtualne przełączniki i lampki przez JTAG: odczyt bieżącej wartości sygnałów i ustawianie sygnałów sterujących w działającym układzie, bez historii przebiegów. Signal Tap/ILA zapisuje historię sygnałów w buforze w takt zegara projektu i pokazuje przebiegi wokół wyzwolenia, ale niczego nie steruje. Łączy się je: VIO ustawia tryb i wyzwala test, ILA zapisuje reakcję.
</details>

2. **Jak przetestujesz zestaw rejestrów peryferium, zanim powstanie oprogramowanie procesora?**

<details>
<summary>Odpowiedź</summary>

Podłączam do magistrali peryferium master sterowany przez JTAG — JTAG-to-Avalon Master Bridge (Platform Designer) albo JTAG-to-AXI Master (Vivado) — i piszę skrypt Tcl w System Console/Hardware Manager, który zapisuje i odczytuje rejestry tak jak przyszły sterownik. Równolegle ILA/Signal Tap na magistrali pokazuje przebieg transakcji.
</details>

3. **Dlaczego odczyt 32-bitowego licznika przez ISSP może dać wartość, której licznik nigdy nie miał?**

<details>
<summary>Odpowiedź</summary>

Sonda jest próbkowana przez logikę JTAG w chwili niezwiązanej z zegarem licznika; jeśli licznik zmienia się w trakcie przechwytywania, część bitów może pochodzić ze starej, a część z nowej wartości (jak przy przesyłaniu liczby binarnej przez synchronizator). Rozwiązania: zatrzaśnięcie wartości w rejestrze na żądanie i odczyt rejestru, odczyt kilkukrotny do zgodności, kod Graya dla liczników.
</details>

### [17.04 — Pomiary zewnętrzne: oscyloskop, analizator logiczny, integralność sygnałów](../modules/17-debug-na-sprzecie/17.04-pomiary-zewnetrzne-oscyloskop-analizator.md)

1. **Jakiego pasma oscyloskopu potrzebujesz do sygnału zegarowego 50 MHz ze zboczami 1 ns?**

<details>
<summary>Odpowiedź</summary>

Decyduje czas narastania, nie częstotliwość: zbocze 1 ns ma pasmo ok. 0,35 GHz, a żeby zmierzyć je z błędem ok. 5 %, oscyloskop powinien mieć czas narastania ok. 3 razy krótszy, czyli pasmo ok. 1 GHz. Do sprawdzenia samej częstotliwości i wypełnienia wystarczy mniej (np. 250–500 MHz), ale kształt zbocza będzie zniekształcony przez przyrząd. Do tego krótka masa sondy i odpowiednia częstotliwość próbkowania.
</details>

2. **Na oscyloskopie widzisz silne dzwonienie na zboczach. Jak sprawdzisz, czy jest prawdziwe?**

<details>
<summary>Odpowiedź</summary>

Zmieniam sposób pomiaru: krótka sprężynka masy zamiast przewodu, masa przy samym punkcie pomiaru, sonda o mniejszej pojemności (aktywna). Jeśli częstotliwość dzwonienia zmienia się z długością masy — to artefakt sondy (rezonans L przewodu masy z C sondy). Jeśli zostaje — prawdziwe: niedopasowanie linii, brak terminacji, zbyt szybkie zbocze; wtedy terminacja szeregowa, mniejszy prąd i wolniejsze zbocze w ustawieniach I/O.
</details>

3. **Kiedy ścieżkę na płytce trzeba traktować jak linię przesyłową?**

<details>
<summary>Odpowiedź</summary>

Gdy czas propagacji wzdłuż ścieżki jest porównywalny z czasem narastania zbocza — praktycznie, gdy przekracza ok. 1/6 t_r. W FR4 sygnał biegnie ok. 15 cm/ns, więc przy zboczu 1 ns ścieżki dłuższe niż ok. 2,5 cm wymagają kontrolowanej impedancji i terminacji. Częstotliwość sygnału nie ma tu znaczenia — wolny sygnał z szybkim zboczem odbija się tak samo.
</details>

### [17.05 — Działa w symulacji, nie działa na płytce — typowe przyczyny](../modules/17-debug-na-sprzecie/17.05-dziala-w-symulacji-nie-dziala-na-plytce-typowe.md)

1. **Projekt działa w symulacji, a na płytce nie. Jakie są możliwe przyczyny i od czego zaczniesz?**

<details>
<summary>Odpowiedź</summary>

Cztery grupy: kod opisuje inny układ niż synteza (lista czułości, opóźnienia, X-optymizm, dyrektywy, przypisania blokujące, zatrzaski); timing (brak ograniczeń, ujemny zapas, CDC, wejścia/wyjścia bez ograniczeń); świat zewnętrzny inny niż testbench (drgania, asynchroniczne wejścia, uproszczone modele, niepełne pokrycie, integralność sygnałów); złe podłączenie (piny, standardy, polaryzacja, zegar, stary bitstream). Zaczynam od najtańszego: podłączenie i zegary, potem raporty syntezy i timingu, potem obserwacja wnętrza (liczniki, ISSP, Signal Tap) i odtworzenie przebiegu w symulacji.
</details>

2. **Czym jest X-optymizm i dlaczego jest groźny?**

<details>
<summary>Odpowiedź</summary>

Gdy warunek `if` ma wartość X (np. rejestr bez resetu), symulator Veriloga traktuje go jak fałsz i wykonuje gałąź `else`; `case` z X wybiera `default` lub żadną gałąź. Symulacja pokazuje więc konkretną, często poprawnie wyglądającą wartość, zamiast X — błąd brakującego resetu jest ukryty. Sprzęt wybierze dowolną gałąź zależnie od stanu po konfiguracji. Środki: reset rejestrów sterujących, asercje na X (`$isunknown`), symulacja netlisty, narzędzia sprawdzające propagację X.
</details>

3. **Dlaczego dyrektywa `full_case` jest niebezpieczna?**

<details>
<summary>Odpowiedź</summary>

Mówi narzędziu syntezy, że nieopisane wartości selektora nie wystąpią, więc synteza nie buduje zatrzasku ani przypisania domyślnego — ale symulator dyrektywy nie widzi i dla tych wartości zachowuje się inaczej (trzyma poprzednią wartość). Symulacja i sprzęt się rozjeżdżają, a jeśli wartość jednak wystąpi, sprzęt daje wynik nieprzewidywalny. Zamiast dyrektywy: jawne `default` (z przypisaniem albo z X do celów weryfikacji) lub w SystemVerilogu `unique`/`priority case`, które sprawdza też symulator.
</details>

## 18 — Pamięci w FPGA

### [18.01 — Bloki pamięci: tryby jedno- i dwuportowe, odczyt podczas zapisu](../modules/18-pamieci/18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md)

1. **Dlaczego pamięć z odczytem asynchronicznym nie trafi do bloku M9K?**

<details>
<summary>Odpowiedź</summary>

Bo M9K ma zawsze rejestrowane wejścia (adres), więc dana pojawia się takt po podaniu adresu — odczyt jest synchroniczny. Opis `assign dout = mem[addr]` wymaga danych w tym samym takcie. W rodzinach z pamięcią rozproszoną (MLAB, LUTRAM) narzędzie użyje LUT jako małej pamięci; w MAX 10 takiej pamięci nie ma, więc powstają rejestry i multiplekser 2^AW:1 na każdy bit.
</details>

2. **Co zwraca blok pamięci przy odczycie adresu zapisywanego w tym samym takcie?**

<details>
<summary>Odpowiedź</summary>

Zależy od trybu i portów. Ten sam port: starą zawartość (READ_FIRST/old data), nową daną (WRITE_FIRST/new data) albo poprzednią wartość wyjścia (NO_CHANGE). Dwa porty z jednym zegarem: w M9K „old data” albo „don't care” zależnie od ustawienia. Dwa różne zegary: wynik nieokreślony. Kod HDL wybiera tryb przez sposób opisu, ale przy dwóch zegarach poprawność musi zapewnić protokół, a nie tryb.
</details>

3. **Masz pamięć 256 × 8 z synchronicznym resetem całej zawartości. Co się stanie w syntezie i jak to poprawić?**

<details>
<summary>Odpowiedź</summary>

Blok pamięci nie kasuje zawartości, więc narzędzie zbuduje 2048 przerzutników z resetem i multipleksery odczytu (w eksperymencie Yosysa: 2056 FF, 2307 LUT4 zamiast jednego bloku). Poprawka: bez resetu tablicy; jeśli trzeba zaczynać od zer — inicjalizacja przy konfiguracji (plik), bit ważności na słowo (w rejestrach albo w osobnej małej pamięci) albo automat, który po resecie zapisuje zera adres po adresie.
</details>

### [18.02 — ROM i inicjalizacja pamięci z pliku (.mif, .hex, .mem)](../modules/18-pamieci/18.02-rom-i-inicjalizacja-pamieci-z-pliku-mif-hex-mem.md)

1. **Jak przenośnie zainicjalizować pamięć w Verilogu i w VHDL?**

<details>
<summary>Odpowiedź</summary>

W Verilogu/SV: `initial $readmemh("plik.hex", mem);` — rozumieją to symulatory i syntezatory Quartus, Vivado, Yosys. W VHDL: funkcja nieczysta czytająca plik przez `textio` w wartości początkowej sygnału pamięci (symulacja, Vivado), a dla Quartusa dodatkowo atrybut `ram_init_file` z plikiem `.mif`; całkowicie przenośnie — pakiet ze stałą tablicą generowany skryptem. Pliki w różnych formatach generuje jeden skrypt z jednego źródła.
</details>

2. **Czy ROM zawsze trafia do bloku pamięci?**

<details>
<summary>Odpowiedź</summary>

Nie. ROM z odczytem synchronicznym może trafić do bloku, ale narzędzie wybiera realizację tańszą według swojego modelu kosztów: mała tablica (np. 256 × 8) bywa tańsza w LUT niż zajęcie całego bloku. ROM z odczytem asynchronicznym zawsze jest logiką. Wybór wymusza atrybut (`romstyle = "M9K"` w Quartusie, `rom_style = "block"` w Vivado i Yosysie) albo ustawienie narzędzia.
</details>

3. **Zmieniłeś tablicę współczynników w pliku .mif. Czy musisz ponownie kompilować projekt?**

<details>
<summary>Odpowiedź</summary>

W Quartusie nie: *Update Memory Initialization File* wczytuje nową zawartość do bazy projektu, a ponowny Assembler generuje `.sof` w kilkadziesiąt sekund, bez syntezy i dopasowania. Na działającym układzie można też podmienić zawartość przez JTAG (*In-System Memory Content Editor*), jeśli pamięć ma włączony identyfikator do edycji. Zawartość pliku nie wpływa na rozmieszczenie ani timing.
</details>

### [18.03 — Synchroniczna kolejka FIFO i flagi](../modules/18-pamieci/18.03-synchroniczna-kolejka-fifo-i-flagi.md)

1. **Czym różni się FIFO w trybie standardowym od FWFT i jak zbudować FWFT na pamięci blokowej?**

<details>
<summary>Odpowiedź</summary>

W standardowym dana pojawia się na wyjściu takt po `rd_en`; w FWFT najstarsza dana już czeka na wyjściu, gdy kolejka nie jest pusta, a `rd_en` ją zdejmuje. Pamięć blokowa ma odczyt synchroniczny, więc FWFT wymaga stopnia wyprzedzenia: rejestr wyjściowy z flagą ważności, ładowany z pamięci, gdy jest pusty albo właśnie zwalniany (`!valid || rd_en`) i pamięć ma dane. `empty = !valid`; pojemność rośnie o jedno słowo; dane pojawiają się na wyjściu 2 takty po zapisie do pustej kolejki.
</details>

2. **Jak liczysz flagi pełna/pusta w FIFO synchronicznym?**

<details>
<summary>Odpowiedź</summary>

Albo licznikiem słów (AW + 1 bitów: +1 przy zapisie, −1 przy odczycie) — pełna przy 2^AW, pusta przy 0 — albo wskaźnikami o jeden bit szerszymi niż adres: równe — pusta, różne tylko najstarszym bitem — pełna. W jednej domenie zegarowej oba sposoby są proste; licznik daje od razu `count` i flagi programowalne.
</details>

3. **Do czego służy almost_full i jak dobrać próg?**

<details>
<summary>Odpowiedź</summary>

Do zatrzymania producenta, który nie reaguje natychmiast — ma potok, wysyła paczkami albo sygnał wstrzymania dochodzi do niego z opóźnieniem. Próg = głębokość minus maksymalna liczba słów, które producent może jeszcze wysłać po zapaleniu flagi (opóźnienie reakcji w taktach × słowa na takt, plus paczka w toku). Za wysoki próg — przepełnienie; za niski — niewykorzystana głębokość.
</details>

### [18.04 — Bufory pierścieniowe, ping-pong i bufory linii](../modules/18-pamieci/18.04-bufory-pierscieniowe-ping-pong-i-bufory-linii.md)

1. **Kiedy użyjesz bufora ping-pong zamiast FIFO?**

<details>
<summary>Odpowiedź</summary>

Gdy odbiorca potrzebuje całego bloku i czyta go w innej kolejności niż zapis (FFT z odwróceniem bitów adresu, transpozycja, przeplot, przetwarzanie ramki), albo gdy nadawca i odbiorca pracują na blokach w potoku: jeden wypełnia bank, drugi w tym czasie przetwarza poprzedni. Koszt: dwa razy pamięć bloku i opóźnienie całego bloku. FIFO wystarcza, gdy dane są konsumowane w kolejności zapisu.
</details>

2. **Jak zbudować okno 3 × 3 na strumieniu pikseli bez pamiętania całego obrazu?**

<details>
<summary>Odpowiedź</summary>

Dwa bufory linii (albo jedna pamięć o słowie 2·W) przechowują dwie poprzednie linie: dla każdego nowego piksela odczytuje się piksele z tej samej kolumny z linii −1 i −2, a na ich miejsce zapisuje {linia −1, bieżący}. Daje to kolumnę trzech pikseli; trzy ostatnie kolumny trzyma 6 rejestrów. Pamięć: 2 × szerokość linii × W bitów, plus logika brzegów obrazu.
</details>

3. **Ile pamięci potrzeba na bufor linii dla filtra 5 × 5 obrazu 1920 × 1080, 24 bity na piksel?**

<details>
<summary>Odpowiedź</summary>

Cztery poprzednie linie × 1920 pikseli × 24 bity = 184 320 bitów (~180 kbit), czyli pojemność 20 bloków M9K (po 9216 bitów). Liczy się jednak organizacja: głębokość 1920 wymaga konfiguracji 2048 × 4 bity, a słowo 4 linii × 24 bity = 96 bitów — razem 96 / 4 = 24 bloki. Dobór szerokości i głębokości bywa ważniejszy niż sama liczba bitów.
</details>

### [18.05 — Pamięć flash użytkownika w MAX 10 (UFM)](../modules/18-pamieci/18.05-pamiec-flash-uzytkownika-w-max-10-ufm.md)

1. **Dlaczego zapis do flasha wymaga wcześniejszego kasowania?**

<details>
<summary>Odpowiedź</summary>

Komórka flash zapisana (zaprogramowana) ma bit 0; programowanie może tylko wprowadzać ładunek, czyli zmieniać 1 w 0. Powrót do 1 wymaga kasowania, które działa na całym bloku (stronie) naraz. Dlatego zapis nowej wartości w miejsce starej wymaga skasowania strony, a bez tego wynik to AND starej i nowej wartości.
</details>

2. **Jak przechowywać często zmieniany licznik w pamięci o 10 000 cyklach kasowania?**

<details>
<summary>Odpowiedź</summary>

Dziennikiem: strona jako tablica rekordów, każda zmiana to zapis w kolejnym wolnym (skasowanym) słowie, wartość bieżąca — ostatni zapisany rekord; kasowanie dopiero po zapełnieniu strony. Przy 2048 słowach na stronę to 2048 zmian na jeden cykl kasowania. Do tego dwie strony na zmianę (zawsze jedna kompletna kopia), numer sekwencyjny i suma kontrolna rekordu, a zapis tylko przy zdarzeniach, nie okresowo.
</details>

3. **Czym UFM w MAX 10 różni się od zewnętrznego EEPROM I²C?**

<details>
<summary>Odpowiedź</summary>

UFM jest w układzie (brak pinów, szybki 32-bitowy odczyt równoległy przez Avalon-MM), ale kasuje się stronami (kilobajty), a nie bajtami, ma 10 000 cykli (EEPROM zwykle 10⁶ cykli i zapis pojedynczego bajtu) i zależy od trybu konfiguracji — ponowne programowanie układu może ją skasować. EEPROM lepiej znosi częste małe zmiany; UFM wygrywa ceną, pojemnością i szybkością odczytu.
</details>

### [18.06 — ECC i ochrona danych w pamięci](../modules/18-pamieci/18.06-ecc-i-ochrona-danych-w-pamieci.md)

1. **Ile bitów kontrolnych potrzebuje kod SECDED dla 64 bitów danych i dlaczego?**

<details>
<summary>Odpowiedź</summary>

Kod Hamminga potrzebuje r bitów, gdzie 2^r ≥ k + r + 1: dla k = 64 r = 7 (128 ≥ 72). SECDED dodaje bit parzystości całego słowa, który rozróżnia błąd pojedynczy (parzystość niezgodna) od podwójnego (parzystość zgodna, syndrom niezerowy): razem 8 bitów, słowo 72 bity — stąd moduły pamięci DDR z ECC mają szynę 72-bitową.
</details>

2. **Jak dekoder SECDED odróżnia błąd pojedynczy od podwójnego?**

<details>
<summary>Odpowiedź</summary>

Błąd pojedynczy zmienia parzystość całego słowa (parzystość ogólna = 1), a syndrom wskazuje pozycję (albo 0, gdy błędny jest sam bit parzystości). Błąd podwójny nie zmienia parzystości ogólnej (dwa odwrócone bity), ale syndrom jest niezerowy — XOR dwóch różnych numerów pozycji. Dekoder: parzystość 1 → popraw bit wskazany przez syndrom; parzystość 0 i syndrom ≠ 0 → zgłoś błąd niepoprawialny.
</details>

3. **Czym jest scrubbing i po co go stosować?**

<details>
<summary>Odpowiedź</summary>

Okresowym czytaniem całej pamięci, poprawianiem słów z pojedynczym błędem i zapisywaniem ich z powrotem. ECC poprawia jeden błąd na słowo; jeśli błędy miękkie gromadzą się w rzadko czytanym słowie, drugi błąd w tym samym słowie czyni je niepoprawialnym. Okres czyszczenia dobiera się do częstości błędów (SER) i wymaganej niezawodności.
</details>

## 19 — Arytmetyka i liczby w sprzęcie

### [19.01 — Stałoprzecinkowe formaty Q: skalowanie, zaokrąglanie, nasycenie](../modules/19-arytmetyka/19.01-staloprzecinkowe-formaty-q-skalowanie.md)

1. **Mnożysz dwie liczby Q1.15. Jaki jest format wyniku i które bity bierzesz, żeby wrócić do Q1.15?**

<details>
<summary>Odpowiedź</summary>

Iloczyn 32-bitowy w formacie Q2.30. Powrót do Q1.15: usunąć 15 bitów ułamka (z zaokrągleniem) i jeden bit części całkowitej — bity [30:15] po zaokrągleniu. Bit 31 jest potrzebny tylko dla (−1)·(−1) = +1, które nie mieści się w Q1.15: tam trzeba nasycić do 0x7FFF (albo zabronić −1 w jednym z operandów, jak robią niektóre biblioteki).
</details>

2. **Dlaczego obcinanie bitów w filtrze IIR jest groźniejsze niż w FIR?**

<details>
<summary>Odpowiedź</summary>

Obcięcie w U2 zaokrągla w stronę −∞, dając średni błąd ok. −½ LSB. W FIR błąd przechodzi przez filtr raz i jest ograniczony. W IIR wynik wraca do sprzężenia zwrotnego, więc błąd się kumuluje: powstaje przesunięcie stałej składowej, a przy małych sygnałach cykle graniczne (wyjście oscyluje albo nie wraca do zera po zaniku wejścia). Rozwiązania: zaokrąglenie zbieżne, więcej bitów w pętli, kształtowanie szumu (sprzężenie błędu kwantyzacji).
</details>

3. **Czy akumulator filtru FIR może się przepełniać w trakcie sumowania?**

<details>
<summary>Odpowiedź</summary>

Może — jeśli działa w kodzie U2 z zawijaniem, a wynik końcowy mieści się w zakresie akumulatora, pośrednie przepełnienia się znoszą (arytmetyka modulo 2ᴺ). Dlatego akumulator zawija, a nasycenie stosuje się dopiero przy zmianie formatu na wyjściu. Bezpiecznie dobiera się szerokość akumulatora jako szerokość iloczynu plus ⌈log₂N⌉ bitów — wtedy nie przepełnia się wcale.
</details>

### [19.02 — Mnożenie i bloki DSP — potokowanie](../modules/19-arytmetyka/19.02-mnozenie-i-bloki-dsp-potokowanie.md)

1. **Jak zaimplementujesz mnożenie 32 × 32 w FPGA z blokami 18 × 18?**

<details>
<summary>Odpowiedź</summary>

Podział na połówki: a = aₕ·2¹⁶ + aₗ, b analogicznie; a·b = aₕbₕ·2³² + (aₕbₗ + aₗbₕ)·2¹⁶ + aₗbₗ — cztery mnożenia 16 × 16 (każde mieści się w bloku 18 × 18, także dla liczb ze znakiem przy części starszej ze znakiem i młodszej bez znaku rozszerzonej zerem) i sumator 64-bitowy. Do potoku: rejestry na wejściach i wyjściach bloków (w bloku), rejestr za iloczynami częściowymi, sumowanie w jednym albo dwóch stopniach. Opóźnienie 3–4 takty, wynik w każdym takcie.
</details>

2. **Kiedy warto mnożyć liczby zespolone trzema mnożeniami zamiast czterech?**

<details>
<summary>Odpowiedź</summary>

Gdy brakuje bloków DSP, a logiki jest pod dostatkiem (FFT, korelatory, miksery cyfrowe w wielu kanałach). Trzy mnożenia wymagają pięciu dodawań zamiast dwóch, sum o bit szerszych przed mnożeniem i dodatkowego stopnia potoku. Gdy jeden czynnik jest stały (współczynniki FFT), dwie z trzech sum przed mnożeniem liczy się z góry — koszt spada. W eksperymencie: 3 bloki i 142 LUT zamiast 4 bloków i 76 LUT.
</details>

3. **Dlaczego dodanie rejestrów za mnożarką 18 × 18 nie podniosło f_max, a za mnożarką 34 × 34 — tak?**

<details>
<summary>Odpowiedź</summary>

Ścieżka krytyczna 18 × 18 to samo opóźnienie bloku między jego rejestrem wejściowym a wyjściowym — kolejne rejestry za blokiem niczego nie skracają, jeśli blok nie ma wewnętrznego rejestru potoku (MREG). W 34 × 34 za blokami jest jeszcze sumator 68-bitowy: rejestr między blokami a sumatorem dzieli ścieżkę na dwie krótsze. Potok pomaga tylko tam, gdzie rozcina rzeczywistą logikę.
</details>

### [19.03 — Dzielenie i pierwiastek: algorytmy iteracyjne](../modules/19-arytmetyka/19.03-dzielenie-i-pierwiastek-algorytmy-iteracyjne.md)

1. **Jak zaimplementujesz dzielenie 32-bitowe w FPGA bez bloków dzielących?**

<details>
<summary>Odpowiedź</summary>

Zależnie od wymaganej przepustowości: (1) iteracyjnie — dzielenie z odtwarzaniem albo bez, bit na takt, 32+ taktów, jeden sumator 33-bitowy; (2) w potoku — 32 stopnie, wynik w każdym takcie, ok. 3·32² przerzutników; (3) podstawa 4 / SRT — 2 bity na takt; (4) przez mnożenie — odwrotność dzielnika z tablicy i dwóch iteracji Newtona–Raphsona, potem mnożenie przez dzielną (kilka bloków DSP, kilka taktów). Do tego definicja przypadków specjalnych: przez zero, przepełnienie dla liczb ze znakiem.
</details>

2. **Dlaczego reszta z dzielenia liczb ze znakiem ma znak dzielnej?**

<details>
<summary>Odpowiedź</summary>

Bo iloraz zaokrągla się w stronę zera (jak w C99, Verilogu, VHDL `/`), a tożsamość a = q·b + r musi być zachowana: −7 / 2 = −3, więc r = −7 − (−3·2) = −1. Przy zaokrąglaniu w dół (floor, jak w Pythonie `//`) iloraz byłby −4, a reszta +1 (znak dzielnika — `mod` w VHDL, `%` w Pythonie). W sprzęcie dzieli się moduły i poprawia znaki: iloraz ujemny, gdy znaki różne, reszta ze znakiem dzielnej.
</details>

3. **Jak policzysz x / 10 bez dzielenia?**

<details>
<summary>Odpowiedź</summary>

Mnożeniem przez przybliżoną odwrotność i przesunięciem: dla 16-bitowego x bez znaku x/10 = (x · 52429) ≫ 19, gdzie 52429 = ⌈2¹⁹/10⌉ — wynik jest dokładny dla wszystkich x < 2¹⁶ (łatwo sprawdzić wyczerpująco; dobór stałej i przesunięcia z dowodem — *Hacker's Delight*, rozdz. 10). W FPGA to jedno mnożenie 16 × 16 bez znaku (mieści się w bloku 18 × 18) i wybór bitów [31:19] iloczynu — bez żadnej logiki dzielącej.
</details>

### [19.04 — CORDIC](../modules/19-arytmetyka/19.04-cordic.md)

1. **Jak CORDIC liczy sinus bez mnożarek?**

<details>
<summary>Odpowiedź</summary>

Obraca wektor (1/K, 0) o zadany kąt serią obrotów o ±atan(2⁻ⁱ). Dzięki wyborowi kątów tg θᵢ = 2⁻ⁱ każdy obrót to przesunięcia i dodawania: x' = x ∓ (y ≫ i), y' = y ± (x ≫ i), a akumulator kąta odejmuje stałą z tablicy. Kierunek zależy od znaku reszty kąta. Pominięte czynniki cos θᵢ dają stałe wzmocnienie K ≈ 1,647, skompensowane wartością początkową. Po N iteracjach x ≈ cos θ, y ≈ sin θ z dokładnością ok. N bitów.
</details>

2. **Ile iteracji i jakie szerokości potrzebne są dla 16-bitowego sinusa?**

<details>
<summary>Odpowiedź</summary>

Ok. 1 bit na iterację, więc N ≈ 18; ścieżka x, y — 16 bitów + 2 na wzmocnienie K·√2 + log₂N ≈ 4 bity ochronne; kąt — co najmniej N + 2…4 bity, żeby atan(2⁻ᴺ) nie zaokrąglał się do zera (tu 24). Model w eksperymencie: N = 18, A = 24, G = 4 daje błąd 1,1 LSB; N = 14 — 4,5 LSB; A = 18 — 3,4 LSB.
</details>

3. **Jak policzyć moduł i fazę liczby zespolonej w FPGA?**

<details>
<summary>Odpowiedź</summary>

CORDIC w trybie wektorowania: obroty w kierunku przeciwnym do znaku y sprowadzają wektor na oś x — x końcowe = K·|v|, suma kątów = atan2(y, x). Obrót wstępny o ±90° dla x < 0 daje pełny zakres ±180°. Kompensacja K jednym mnożeniem przez 1/K (albo pominięta, jeśli moduł służy do porównań). Alternatywy: |v|² = x² + y² dwoma mnożeniami (bez pierwiastka) albo przybliżenie „alpha max + beta min”.
</details>

### [19.05 — Liczby zmiennoprzecinkowe w FPGA: IEEE 754 i rdzenie IP](../modules/19-arytmetyka/19.05-liczby-zmiennoprzecinkowe-w-fpga-ieee-754-i.md)

1. **Opisz kroki dodawania dwóch liczb binary32 w sprzęcie.**

<details>
<summary>Odpowiedź</summary>

(1) Rozpakowanie, obsługa NaN, ∞, zer; (2) uporządkowanie operandów tak, by |a| ≥ |b|, różnica wykładników d; (3) przesunięcie mantysy b o d w prawo (przesuwnik beczkowy) z zachowaniem bitów guard/round/sticky; (4) dodanie lub odjęcie mantys zależnie od znaków; (5) normalizacja — przy przeniesieniu przesunięcie o 1 w prawo, przy odejmowaniu licznik zer wiodących i przesunięcie w lewo; (6) zaokrąglenie (połówka do parzystej) i ewentualna ponowna normalizacja; (7) kontrola nadmiaru i niedomiaru. Ścieżka krytyczna: dwa przesuwniki i LZC — dlatego potok 5–10 stopni.
</details>

2. **Co to są bity guard, round i sticky?**

<details>
<summary>Odpowiedź</summary>

Informacja o odrzucanej części wyniku, wystarczająca do poprawnego zaokrąglenia: guard — pierwszy bit za mantysą, round — drugi, sticky — OR wszystkich dalszych (czy cokolwiek niezerowego zostało odrzucone). Do najbliższej z połówką do parzystej: zaokrąglić w górę, gdy guard = 1 i (round lub sticky = 1 albo najmłodszy bit wyniku = 1). Przy mnożeniu wystarczą guard i sticky, przy dodawaniu round jest potrzebny, bo po odejmowaniu wynik może przesunąć się o bit w lewo.
</details>

3. **Kiedy w FPGA wybrałbyś liczby zmiennoprzecinkowe zamiast stałoprzecinkowych?**

<details>
<summary>Odpowiedź</summary>

Gdy zakres wartości jest nieznany albo bardzo duży i analiza zakresów w każdym węźle byłaby kosztowna lub ryzykowna: inwersja i rozkład macierzy, filtry Kalmana, obliczenia naukowe, uczenie sieci, algorytmy iteracyjne o zmiennej dynamice. Także gdy układ ma hardware'owe FP w DSP (Arria 10, Agilex, Versal) i koszt jest niewielki, albo gdy liczy się czas wdrożenia (HLS z kodu C). Dla torów sygnałowych o znanym zakresie (ADC, audio, radio, obraz) stały przecinek daje to samo za ułamek zasobów i deterministycznie.
</details>

### [19.06 — Tablice i aproksymacja funkcji](../modules/19-arytmetyka/19.06-tablice-i-aproksymacja-funkcji.md)

1. **Jak zaimplementujesz 16-bitowy log₂ w FPGA?**

<details>
<summary>Odpowiedź</summary>

Redukcja argumentu: licznik zer wiodących daje część całkowitą (pozycja najstarszej jedynki), a znormalizowana mantysa m ∈ [1, 2) — część ułamkową log₂ m. log₂ m aproksymuje się tablicą z interpolacją liniową (np. 64 odcinki — 1 mnożarka, dwie małe tablice) albo wielomianem 2. stopnia; minimax zamiast cięciwy. Wynik: log₂ x = (pozycja jedynki) + log₂ m w formacie stałoprzecinkowym. Weryfikacja wyczerpująca po wszystkich 65 536 wejściach.
</details>

2. **Masz 1024 słowa pamięci na funkcję sinus. Jak uzyskać najlepszą dokładność?**

<details>
<summary>Odpowiedź</summary>

Wykorzystać symetrię — tablica tylko dla ćwiartki okresu (4 razy większa gęstość). Zamiast samych wartości zapisać współczynniki interpolacji: 512 odcinków × (wartość, nachylenie) z jedną mnożarką — błąd spada z rzędu f′·h/2 do f″·h²/8, czyli o kilka rzędów wielkości (w eksperymencie 128 słów z interpolacją pobiło 4096 słów bez niej). Współczynniki minimax, 2–3 bity ochronne. Alternatywnie tożsamość sin(a + b) = sin a·cos b + cos a·sin b z dwiema mniejszymi tablicami.
</details>

3. **Czym różni się aproksymacja cięciwą od minimax?**

<details>
<summary>Odpowiedź</summary>

Cięciwa przechodzi przez wartości funkcji na końcach odcinka — dla funkcji wypukłej albo wklęsłej błąd ma jeden znak i największą wartość f″·h²/8 w środku. Minimax minimalizuje największy błąd bezwzględny: prosta przesunięta tak, by błąd osiągał +e i −e na przemian (twierdzenie Czebyszewa o alternansie) — dla prostej to cięciwa przesunięta o połowę odchylenia, czyli błąd o połowę mniejszy. Dla wielomianów wyższych stopni współczynniki minimax liczy algorytm Remeza (Sollya, numpy).
</details>

## 20 — Interfejsy szeregowe niskiej szybkości

### [20.01 — UART: nadajnik, odbiornik i nadpróbkowanie](../modules/20-interfejsy-szeregowe/20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md)

1. **Dlaczego odbiornik UART próbkuje 16 razy na bit, skoro bit trzeba odczytać raz?**

<details>
<summary>Odpowiedź</summary>

Odbiornik nie ma zegara nadajnika — jedyna informacja o fazie to zbocze opadające bitu startu. Nadpróbkowanie pozwala wykryć to zbocze z dokładnością 1/16 bitu i potem odliczać do środka kolejnych bitów, gdzie sygnał jest najstabilniejszy i najdalej od zboczy. Dodatkowo kilka próbek w środku bitu daje decyzję większościową odporną na krótkie zakłócenia, a sprawdzenie środka bitu startu odrzuca fałszywe starty. Bez nadpróbkowania (próbka raz na bit) faza próbkowania byłaby przypadkowa — w najgorszym razie na samym zboczu.
</details>

2. **Nadajnik ma zegar o 3 % szybszy, odbiornik o 2 % wolniejszy. Czy łącze 8N1 zadziała?**

<details>
<summary>Odpowiedź</summary>

Liczy się suma, czyli ok. 5 % różnicy. Ostatnia decyzja zapada w środku bitu stopu, ok. 9,5 bitu po zboczu startu: przesunięcie 9,5 · 0,05 ≈ 0,48 bitu — przy niepewności wykrycia startu (1/16) i szerokości okna próbek decyzja wypada na granicy bitu albo za nią. Łącze będzie gubić część bajtów (zależnie od danych — błąd pojawi się, gdy sąsiedni bit ma inną wartość). Typowy budżet to ok. 4 % łącznie, praktycznie ±2 % na stronę.
</details>

3. **Co to jest błąd ramki i co może go powodować?**

<details>
<summary>Odpowiedź</summary>

W miejscu bitu stopu odbiornik odczytał 0 zamiast 1. Przyczyny: niezgodna szybkość (najczęściej), zakłócenie, odbiornik zsynchronizował się na bit danych zamiast na start (np. podłączony w środku strumienia), stan *break* (nadajnik trzyma linię nisko dłużej niż ramka — używany jako sygnał specjalny, np. w LIN i DMX512). Odbiornik zwykle zgłasza bajt z flagą błędu, a protokół wyższej warstwy decyduje, co dalej.
</details>

### [20.02 — SPI: master i slave, tryby CPOL/CPHA](../modules/20-interfejsy-szeregowe/20.02-spi-master-i-slave-tryby-cpol-cpha.md)

1. **Czym różnią się tryby SPI 0 i 1? Co się stanie, gdy master i slave mają różne tryby?**

<details>
<summary>Odpowiedź</summary>

Oba mają SCLK w spoczynku niski (CPOL = 0). W trybie 0 dane próbkuje się na zboczu narastającym (wiodącym), a pierwszy bit musi być na linii już po opadnięciu CS; w trybie 1 pierwszy bit wystawia zbocze narastające, a próbkuje się na opadającym. Przy niezgodności strona próbkująca odczytuje bit w chwili, gdy druga go zmienia — wynik zależy od opóźnień: albo dane przesunięte o jeden bit (najstarszy bit zgubiony, na końcu śmieć), albo losowe błędy. Typowy objaw: „prawie dobre” wartości, np. dwukrotnie za duże.
</details>

2. **Jak odczytać rejestr układu SPI, skoro SPI nie ma kierunku transmisji?**

<details>
<summary>Odpowiedź</summary>

Kierunek wynika z protokołu układu, nie z SPI. Zwykle pierwszy bajt zawiera adres i bit odczytu (LIS2DH12: bit 7 = 1 odczyt, bit 6 = autoinkrementacja adresu), slave w tym czasie wysyła nieistotne bity. W kolejnych bajtach master wysyła cokolwiek (zwykle 0x00 albo 0xFF), a slave wysyła zawartość rejestrów. CS musi zostać niski przez całą transakcję. Master po prostu odrzuca bajty odebrane podczas wysyłania adresu.
</details>

3. **Projektujesz SPI slave w FPGA z zegarem 50 MHz. Do jakiej częstotliwości SCLK może działać wersja z nadpróbkowaniem i co zrobić, gdy potrzeba więcej?**

<details>
<summary>Odpowiedź</summary>

Wejścia przechodzą przez dwustopniowy synchronizator, potem detektor zbocza i rejestr wyjścia MISO — to 3–4 takty od zbocza SCLK do zmiany MISO. Nowy bit musi być na linii przed następnym zboczem próbkującym mastera, czyli w pół okresu SCLK, z zapasem na opóźnienia pinów. Przy 50 MHz to SCLK rzędu 5–6 MHz. Szybciej: taktować rejestr przesuwny bezpośrednio zboczem SCLK (osobna domena zegarowa z ograniczeniem czasowym), a gotowe słowo przekazywać do domeny systemowej synchronizatorem z potwierdzeniem albo przez asynchroniczne FIFO.
</details>

### [20.03 — I²C: master, open-drain i rozciąganie zegara](../modules/20-interfejsy-szeregowe/20.03-i2c-master-open-drain-i-rozciaganie-zegara.md)

1. **Jak zrealizować wyjście open-drain w FPGA, które nie ma takich pinów?**

<details>
<summary>Odpowiedź</summary>

Buforem trójstanowym, którego wejście danych jest na stałe 0, a sterowane jest tylko włączenie wyjścia: `pin <= '0' when oe = '1' else 'Z'`. Odczyt linii z tego samego pinu, przez synchronizator. Jedynkę daje rezystor podciągający (zewnętrzny albo słabe podciąganie w bloku I/O). Wewnątrz FPGA nie ma linii trójstanowych — bufor powstaje w bloku I/O, a logika operuje osobnymi sygnałami `oe` i `i`. Część rodzin ma też atrybut pinu *open drain*, który robi to samo.
</details>

2. **Co to jest rozciąganie zegara i jak master musi je obsłużyć?**

<details>
<summary>Odpowiedź</summary>

Slave, który potrzebuje czasu (przygotowanie danych, zapis), przytrzymuje SCL w stanie niskim po zboczu opadającym mastera. Master po zwolnieniu SCL nie może założyć, że linia jest wysoka — musi odczytać SCL i zacząć odmierzać czas stanu wysokiego dopiero, gdy linia faktycznie wzrośnie. Inaczej skróci stan wysoki albo ściągnie SCL, zanim slave go zwolnił. Ten sam mechanizm obsługuje wolne narastanie linii i synchronizację zegarów wielu masterów.
</details>

3. **Dobierz rezystory podciągające dla 400 kHz, 3,3 V i pojemności linii 150 pF.**

<details>
<summary>Odpowiedź</summary>

t_r ≤ 300 ns w trybie Fm, t_r = 0,8473·R_p·C_b → R_p(max) = 300 ns / (0,8473·150 pF) ≈ 2,36 kΩ. R_p(min) = (3,3 − 0,4) V / 3 mA ≈ 0,97 kΩ. Wybór: 1,5–2,2 kΩ (np. 2,2 kΩ — mniejszy prąd, jeszcze w granicy czasu narastania). Wewnętrzne podciąganie FPGA (dziesiątki kΩ) byłoby o rząd wielkości za słabe.
</details>

### [20.04 — PWM, enkodery kwadraturowe i serwomechanizmy](../modules/20-interfejsy-szeregowe/20.04-pwm-enkodery-kwadraturowe-i-serwomechanizmy.md)

1. **Co to jest czas martwy i jak go zrealizować w FPGA?**

<details>
<summary>Odpowiedź</summary>

Odstęp, w którym oba tranzystory gałęzi mostka są wyłączone przy każdym przełączeniu — bo tranzystor wyłącza się wolniej, niż włącza, a jednoczesne przewodzenie zwiera zasilanie. W FPGA: z jednego sygnału odniesienia robi się dwa wyjścia; przy każdej zmianie odniesienia oba wyjścia idą w stan wyłączony, licznik odmierza N taktów i dopiero wtedy włącza się wyjście zgodne z nowym odniesieniem. Długość dobiera się z czasu wyłączania tranzystora i opóźnień sterownika z zapasem. Wyjścia powinny być rejestrowane (bez szpilek z logiki kombinacyjnej), a sterownik bramek powinien mieć własną blokadę.
</details>

2. **Jak określić kierunek obrotu z sygnałów enkodera kwadraturowego i ile kroków na obrót da enkoder 1000 CPR?**

<details>
<summary>Odpowiedź</summary>

A i B są przesunięte o 90°: przy ruchu w przód A zmienia się przed B, sekwencja stanów (A, B) to 00 → 10 → 11 → 01. Porównanie poprzedniego i bieżącego stanu (tablica 16 przejść) daje +1, −1, brak ruchu albo błąd (zmiana obu bitów). Dekodując każde zbocze A i B (×4), 1000 CPR daje 4000 kroków na obrót. Wejścia trzeba zsynchronizować i przefiltrować.
</details>

3. **Dlaczego w sterowaniu silnikami stosuje się PWM centrowany zamiast zwykłego?**

<details>
<summary>Odpowiedź</summary>

Przy PWM wyrównanym do krawędzi wszystkie fazy włączają się na początku okresu — skoki prądu i zakłóceń sumują się, a harmoniczne są większe. W centrowanym impulsy są symetryczne wokół środka okresu, więc fazy o różnych wypełnieniach przełączają w różnych chwilach, widmo prądu jest korzystniejsze, a środek impulsu jest stałym punktem, w którym prąd uzwojenia równa się średniej — tam wyzwala się pomiar prądu przez ADC. Kosztem jest połowa częstotliwości PWM przy tym samym zegarze i liczniku.
</details>

### [20.05 — Czujniki na DECA: akcelerometr, temperatura i wilgotność](../modules/20-interfejsy-szeregowe/20.05-czujniki-na-deca-akcelerometr-temperatura-i.md)

1. **Uruchamiasz nowy czujnik SPI i dostajesz same 0xFF. Jak szukasz przyczyny?**

<details>
<summary>Odpowiedź</summary>

0xFF zwykle znaczy, że MISO jest w spoczynku wysokim — slave nie odpowiada. Kolejno: zasilanie i reset czujnika (czas rozruchu), czy CS dochodzi do właściwego układu i jest aktywny niskim, czy SCLK ma właściwy poziom spoczynkowy i częstotliwość nie przekracza maksimum, tryb CPOL/CPHA zgodny z kartą, format pierwszego bajtu (bit odczytu!), przypisanie pinów i kierunki buforów w FPGA. Pierwszy odczyt to rejestr identyfikacyjny — znana wartość potwierdza całą ścieżkę. Analizator logiczny albo Signal Tap na liniach SPI rozstrzyga, czy problem jest po stronie FPGA, czy czujnika.
</details>

2. **Czujnik I²C odpowiada NACK na swój adres co któryś odczyt. Czy to błąd?**

<details>
<summary>Odpowiedź</summary>

Niekoniecznie. Część układów (HDC1000, wiele pamięci EEPROM w trakcie zapisu stron) celowo nie potwierdza adresu, gdy są zajęte — to ich sposób sygnalizacji gotowości (tzw. *acknowledge polling*). Sterownik powinien wtedy wysłać STOP, odczekać i ponowić. Błędem jest NACK stały (zły adres, brak podciągania, czujnik nie zasilony) albo NACK na bajt danych, którego układ powinien przyjąć. Warto liczyć NACK w liczniku diagnostycznym.
</details>

3. **Jak przeliczyć surowy kod HDC1000 na °C w FPGA bez dzielenia?**

<details>
<summary>Odpowiedź</summary>

T = s·165/65536 − 40. Dzielenie przez 2¹⁶ to wzięcie górnych bitów iloczynu, więc wystarczy mnożenie przez stałą 165 (blok DSP albo suma przesunięć: 165 = 128 + 32 + 4 + 1), wybranie bitów [23:16] i odjęcie 40. Wynik jest obcięty do całych stopni; dla zaokrąglenia dodaje się 2¹⁵ przed wybraniem bitów, a dla ułamków bierze się dodatkowe bity iloczynu (format Q, [19.01](../modules/19-arytmetyka/19.01-staloprzecinkowe-formaty-q-skalowanie.md)).
</details>

### [20.06 — Wbudowany przetwornik ADC w MAX 10](../modules/20-interfejsy-szeregowe/20.06-wbudowany-przetwornik-adc-w-max-10.md)

1. **Rdzeń ADC nie ma sygnału ready po stronie odpowiedzi. Jakie to ma konsekwencje dla projektu logiki odbierającej?**

<details>
<summary>Odpowiedź</summary>

Odpowiedź jest ważna tylko w takcie `response_valid` — logika musi ją przyjąć bezwarunkowo, bez czekania na dalszy tor. Jeśli konsument danych bywa zajęty (np. pisze do wolnej pamięci albo wysyła UART), między rdzeniem a nim musi być bufor: rejestr ostatniej wartości per kanał (gdy ważna jest tylko najnowsza próbka) albo FIFO o głębokości pokrywającej najdłuższą przerwę konsumenta (gdy liczy się każda próbka). Szybkość rozkazów można ograniczyć, żeby odpowiedzi nie przychodziły szybciej, niż konsument średnio nadąża.
</details>

2. **Ile bitów rozdzielczości zyskuje się, uśredniając 256 próbek 12-bitowego przetwornika?**

<details>
<summary>Odpowiedź</summary>

Dla szumu nieskorelowanego odchylenie maleje √256 = 16 razy, co odpowiada 4 bitom — teoretycznie 16 bitów skutecznych, pod warunkiem że szum na wejściu jest rzędu co najmniej 1 LSB (inaczej wszystkie próbki dają ten sam kod i średnia niczego nie poprawi — wtedy dodaje się celowo szum, *dithering*). Przepustowość spada 256 razy, a błędy systematyczne (INL, przesunięcie, wzmocnienie) zostają.
</details>

3. **Jak przeliczyć kod czujnika z nieliniową charakterystyką na jednostki w FPGA?**

<details>
<summary>Odpowiedź</summary>

Gdy zakres kodów jest mały (jak termodioda MAX 10: ok. 370 kodów), najprościej tablica adresowana kodem — jeden blok pamięci, odczyt w jednym takcie. Przy szerokim zakresie: tablica dla wybranych punktów i interpolacja liniowa między nimi (mnożenie i dodawanie, [19.06](../modules/19-arytmetyka/19.06-tablice-i-aproksymacja-funkcji.md)), albo wielomian niskiego stopnia. Zawartość tablicy generuje się skryptem z danych producenta albo liczy funkcją przy elaboracji, a test sprawdza punkty z dokumentacji i monotoniczność.
</details>

## 21 — Magistrale i interfejsy na chipie

### [21.01 — Strumienie z handshakiem: AXI4-Stream i Avalon-ST](../modules/21-magistrale-on-chip/21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md)

1. **Dlaczego w AXI nadajnik nie może czekać na TREADY z ustawieniem TVALID?**

<details>
<summary>Odpowiedź</summary>

Bo odbiornik ma prawo czekać na TVALID z ustawieniem TREADY (np. FIFO, które wystawia ready dopiero, gdy ma czym się zająć, albo układ, który przyjmuje dane tylko w określonych chwilach). Gdyby obie strony czekały na siebie, nastąpiłoby zakleszczenie. Specyfikacja rozstrzyga to jednostronnie: zależność wolno mieć tylko w jednym kierunku — ready może zależeć od valid, valid od ready nie.
</details>

2. **Co to jest skid buffer i kiedy jest potrzebny?**

<details>
<summary>Odpowiedź</summary>

Bufor z dwoma rejestrami (wyjściowym i zapasowym), który rejestruje zarówno dane, jak i sygnał ready, zachowując przepustowość jednego słowa na takt. Gdy odbiornik zatrzyma strumień, nadajnik dowiaduje się o tym takt później (ready jest z rejestru) — słowo wysłane w tym takcie trafia do rejestru zapasowego zamiast przepaść. Potrzebny, gdy kombinacyjna ścieżka ready przez wiele etapów potoku ogranicza f_max albo gdy interfejs przechodzi przez duży odcinek układu (między regionami, SLR).
</details>

3. **Jak przekształcić strumień 8-bitowy w 32-bitowy i co zrobić z pakietem, którego długość nie jest wielokrotnością 4?**

<details>
<summary>Odpowiedź</summary>

Zbierać bajty w rejestrze, wpisując każdy na kolejną pozycję (pierwszy bajt w bitach 7:0), i wysłać słowo po czwartym bajcie. Gdy przyjdzie bajt z TLAST, słowo wysyła się od razu jako niepełne: TKEEP ma jedynki tylko dla zapisanych bajtów, TLAST = 1, a składanie zaczyna się od nowa. W Avalon-ST zamiast maski podaje się `empty` = liczba pustych bajtów.
</details>

### [21.02 — Rejestry sterujące: AXI4-Lite i Avalon-MM](../modules/21-magistrale-on-chip/21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md)

1. **W slave'ie AXI4-Lite dane zapisu przyszły przed adresem. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Przyjmuję je (WREADY = 1, jeśli mam wolny rejestr na dane) i zapamiętuję razem z WSTRB, a WREADY opada, dopóki zapis się nie wykona. Gdy przyjdzie adres, mam komplet — wykonuję zapis i wystawiam BVALID. AW i W są w AXI niezależnymi kanałami; slave może też czekać na oba (trzymać ready = 0), ale nie może zakładać, że przyjdą w tym samym takcie, a master nie może uzależniać wystawienia jednego od ready drugiego.
</details>

2. **Czym różni się SLVERR od DECERR?**

<details>
<summary>Odpowiedź</summary>

SLVERR zgłasza slave, który dostał transakcję, ale nie może jej wykonać (adres w jego zakresie bez rejestru, błąd urządzenia, zapis do zablokowanego rejestru). DECERR zgłasza interconnect (zwykle wbudowany *default slave*), gdy pod adresem nie ma żadnego slave'a. Dla oprogramowania oba kończą się zwykle wyjątkiem magistrali, ale rozróżnienie mówi, czy błąd jest w mapie adresów systemu, czy w konkretnym bloku.
</details>

3. **Dlaczego flagi przerwań robi się jako W1C, a nie zwykły rejestr RW?**

<details>
<summary>Odpowiedź</summary>

Bo przy RW skasowanie jednej flagi wymaga odczytu, zmiany bitu i zapisu — a zdarzenie, które przyjdzie między odczytem i zapisem, zostanie nadpisane zerem i zgubione. W1C kasuje tylko bity zapisane jedynką, pozostałe zostają, a sprzęt nadal może ustawiać nowe. Logika musi przy tym dać pierwszeństwo zdarzeniu przychodzącemu w takcie kasowania.
</details>

### [21.03 — AXI4 i Avalon-MM z burstami](../modules/21-magistrale-on-chip/21.03-axi4-i-avalon-mm-z-burstami.md)

1. **Podaj adresy burstu WRAP: ARADDR = 0x1C, ARSIZE = 2, ARLEN = 3.**

<details>
<summary>Odpowiedź</summary>

S = 4 bajty, L = 4 takty, okno = 16 bajtów wyrównane do 16: 0x10–0x1F. Adresy: 0x1C, potem 0x20 przekracza okno → 0x10, dalej 0x14, 0x18. Czyli 0x1C, 0x10, 0x14, 0x18. Tak pamięć podręczna wczytuje linię 16 bajtów, zaczynając od słowa, na które czeka procesor (*critical word first*).
</details>

2. **Dlaczego burst AXI nie może przekroczyć granicy 4 KB?**

<details>
<summary>Odpowiedź</summary>

Bo 4 KB to najmniejsza jednostka przydziału przestrzeni adresowej (strona pamięci wirtualnej, minimalny zakres slave'a w interconnectcie). Interconnect dekoduje tylko adres startowy burstu i kieruje cały burst do jednego slave'a; gdyby burst przekroczył granicę, część danych trafiłaby do niewłaściwego urządzenia. Reguła przerzuca na mastera obowiązek dzielenia transferów i upraszcza wszystkie slave'y i dekodery.
</details>

3. **Do czego służy AXI ID, skoro odpowiedzi i tak wracają do mastera?**

<details>
<summary>Odpowiedź</summary>

Pozwala na wiele transakcji w toku i na odpowiedzi poza kolejnością: slave (np. kontroler DDR z bankami) może oddać najpierw dane dostępne szybciej, o ile należą do innego ID. Master używa różnych ID dla niezależnych strumieni (np. odczytu instrukcji i danych), a tego samego, gdy potrzebuje zachowania kolejności. Interconnect dokleja do ID numer mastera, żeby skierować odpowiedź do właściwego źródła.
</details>

### [21.04 — Wishbone i magistrale otwarte](../modules/21-magistrale-on-chip/21.04-wishbone-i-magistrale-otwarte.md)

1. **Czym różni się Wishbone potokowy od klasycznego i ile wynosi przepustowość każdego?**

<details>
<summary>Odpowiedź</summary>

W klasycznym master czeka na ACK przed podaniem następnego żądania — z rejestrowanym ACK to jedno słowo na dwa takty (słowo na takt tylko z ACK kombinacyjnym albo z burstami *registered feedback*). W potokowym żądanie jest przyjęte, gdy slave nie zgłasza STALL, master podaje kolejne od razu, a ACK przychodzą później w kolejności żądań — słowo na takt przy rejestrowanych sygnałach. Potokowy wymaga od mastera liczenia żądań w toku.
</details>

2. **Jak podłączyć slave'a Wishbone klasycznego do mastera potokowego?**

<details>
<summary>Odpowiedź</summary>

Wystawić STALL = ¬ACK (przy aktywnym STB): dopóki slave nie odpowie, master widzi „zajęty” i nie uważa żądania za przyjęte ani nie podaje następnego. W takcie ACK STALL = 0, więc żądanie jest przyjęte, a ACK liczy się jako odpowiedź. Przepustowość spada do tempa slave'a klasycznego, ale protokół się zgadza. Odwrotny kierunek (master klasyczny, slave potokowy) wymaga trzymania STB tylko do przyjęcia i czekania na ACK.
</details>

3. **Dlaczego AXI ma pięć kanałów, a Wishbone jeden? Co daje każde podejście?**

<details>
<summary>Odpowiedź</summary>

Wishbone przesyła adres, dane i kierunek razem, a odpowiedzi wracają w kolejności — mało sygnałów, prosta logika, dobre dla małych systemów. AXI rozdziela adres zapisu, dane zapisu, odpowiedź, adres odczytu i dane odczytu, a ID pozwala na odpowiedzi poza kolejnością. Dzięki temu odczyty i zapisy idą równolegle, wiele transakcji może być w toku, a slave z różnym opóźnieniem (DDR) nie blokuje innych — kosztem większej logiki i trudniejszej weryfikacji.
</details>

### [21.05 — Mapa rejestrów i generatory: SystemRDL, PeakRDL](../modules/21-magistrale-on-chip/21.05-mapa-rejestrow-i-generatory-systemrdl-peakrdl.md)

1. **Po co opisywać rejestry w SystemRDL albo IP-XACT, skoro RTL można napisać ręcznie?**

<details>
<summary>Odpowiedź</summary>

Bo mapa rejestrów jest potrzebna w wielu postaciach — RTL, nagłówki i sterowniki C, dokumentacja, model rejestrów UVM, skrypty testowe — i ręczne utrzymywanie ich spójności prowadzi do błędów, które wychodzą dopiero przy integracji z oprogramowaniem. Opis w jednym języku generuje wszystkie postacie naraz, standaryzuje zachowania pól (W1C, impulsy, liczniki) i pozwala zmieniać magistralę bez zmiany logiki rejestrów.
</details>

2. **Jak opisać w SystemRDL rejestr flag przerwań z maską?**

<details>
<summary>Odpowiedź</summary>

Pole flag jako `intr` (bit lepki ustawiany przez sprzęt) z `sw = rw` i `onwrite = woclr` — zapis jedynki kasuje. Osobny rejestr maski z polem `sw = rw`. Połączenie właściwością `enable` (albo `mask`) pola przerwań: `FLAGI.pole->enable = MASKA.pole;`. Generator tworzy wyjście przerwania rejestru (OR bitów włączonych maską) i wejścia zdarzeń dla sprzętu.
</details>

3. **Czym różni się generowany blok rejestrów od ręcznie napisanego slave'a, jeśli chodzi o weryfikację?**

<details>
<summary>Odpowiedź</summary>

Generator jest zweryfikowany przez jego autorów dla wszystkich obsługiwanych konstrukcji, więc nie testuje się ponownie protokołu i logiki pól w każdym projekcie — wystarczy test integracji: czy sprzęt poprawnie używa wyjść i wejść `hwif`, czy adresy w oprogramowaniu pochodzą z wygenerowanego nagłówka. Ręczny slave wymaga pełnej weryfikacji protokołu (jak `tb_rejestry` w 21.02). Generator daje też model rejestrów (UVM RAL), z którego testbench korzysta zamiast ręcznych adresów.
</details>

### [21.06 — Platform Designer i IP Integrator](../modules/21-magistrale-on-chip/21.06-platform-designer-i-ip-integrator.md)

1. **Co musi zawierać opis komponentu dla Platform Designer albo IP Integratora, żeby własny blok z rejestrami dało się podłączyć do procesora?**

<details>
<summary>Odpowiedź</summary>

Pliki HDL i moduł najwyższego poziomu; interfejs zegara i resetu (z biegunowością i sposobem zwalniania); interfejs slave'a magistrali (Avalon-MM albo AXI4-Lite) z mapowaniem portów na role sygnałów i własnościami: jednostki adresu, opóźnienie odczytu albo sygnał ważności, maksymalne odczyty w toku, obsługa burstów, związany zegar i reset; interfejs przerwania, jeśli blok je zgłasza; sygnały zewnętrzne jako conduit/external; parametry przekazywane do HDL. Narzędzie wygeneruje interconnect zgodnie z tymi deklaracjami, więc muszą one dokładnie odpowiadać zachowaniu RTL.
</details>

2. **Jak uruchomić i przetestować nowy blok z rejestrami na płytce, zanim powstanie oprogramowanie?**

<details>
<summary>Odpowiedź</summary>

Dodać do systemu mastera sterowanego przez JTAG (JTAG to Avalon Master Bridge albo JTAG to AXI Master), połączyć go ze slave'em bloku i skryptem w System Console (albo Vivado Hardware Manager) wykonywać odczyty i zapisy rejestrów pod adresami z mapy: sprawdzić rejestr ID, zapisy i odczyty, reakcję sprzętu. Skrypt można rozbudować do testu regresyjnego. Do obserwacji sygnałów wewnątrz — Signal Tap/ILA wyzwalane dostępem do rejestru.
</details>

3. **Dlaczego system Platform Designer albo block design trzyma się w repozytorium jako skrypt Tcl?**

<details>
<summary>Odpowiedź</summary>

Pliki `.qsys`/`.bd` to XML zależny od wersji narzędzia, z identyfikatorami i informacjami o generacji — różnice między wersjami są nieczytelne, a konflikty przy łączeniu gałęzi trudne do rozwiązania. Skrypt Tcl opisuje intencję (instancje, połączenia, adresy), jest krótki, czytelny w przeglądzie kodu i zwykle działa w nowszych wersjach narzędzia. Wygenerowany system i HDL powstają w budowaniu, jak każdy inny plik pośredni.
</details>

## 22 — Wejścia-wyjścia i szybkie interfejsy

### [22.01 — Standardy I/O, terminacja, siła sterowania i slew rate](../modules/22-io-i-szybkie-interfejsy/22.01-standardy-i-o-terminacja-sila-sterowania-i-slew.md)

1. **Sygnał zegara 10 MHz z FPGA na drugą płytkę przez 30 cm kabla taśmowego powoduje podwójne zliczanie. Dlaczego i co zrobić?**

<details>
<summary>Odpowiedź</summary>

Zbocze FPGA trwa ułamek nanosekundy, a kabel ma kilka ns opóźnienia — to linia transmisyjna. Niedopasowany koniec (wejście CMOS) odbija falę, sygnał dzwoni i przekracza próg kilka razy na jednym zboczu. Rozwiązania: rezystor szeregowy przy nadajniku dobrany do impedancji kabla (minus rezystancja wyjścia), mniejszy prąd i wolny slew rate, przeplot sygnału z masą w kablu, wejście z przerzutnikiem Schmitta, a przy dłuższych połączeniach — sygnał różnicowy (LVDS, RS-422).
</details>

2. **Czym różni się terminacja szeregowa od równoległej i kiedy wybierasz którą?**

<details>
<summary>Odpowiedź</summary>

Szeregowa: rezystor przy nadajniku, razem z rezystancją wyjścia równy Z0. Fala połowy amplitudy biegnie do końca, odbija się (całkowicie od wejścia o dużej impedancji), daje pełną amplitudę na końcu i jest pochłaniana przy źródle. Nie pobiera prądu statycznego, ale pełny sygnał jest tylko na końcu linii — dobra dla połączeń punkt–punkt. Równoległa: rezystor Z0 na końcu do masy, VCC albo VTT — brak odbicia i pełny sygnał wszędzie, ale prąd statyczny; stosowana w magistralach z wieloma odbiornikami i w standardach typu SSTL (pamięci DDR).
</details>

3. **Dlaczego nie ustawić maksymalnej siły sterowania i najszybszego slew rate na wszystkich pinach, żeby mieć największy zapas czasowy?**

<details>
<summary>Odpowiedź</summary>

Bo szybkie, silne zbocza powodują dzwonienie na niedopasowanych liniach, przesłuch na sąsiednie ścieżki, emisję zakłóceń (EMI) i szum jednoczesnego przełączania — prąd wielu wyjść przez indukcyjność wyprowadzeń masy unosi masę układu i może przełączyć wejścia albo zakłócić inne wyjścia. Wybiera się najsłabsze ustawienie, które jeszcze spełnia wymagania czasowe, a szybkie sygnały dopasowuje się impedancyjnie (OCT).
</details>

### [22.02 — Rejestry DDR w I/O i interfejsy źródłowo-synchroniczne](../modules/22-io-i-szybkie-interfejsy/22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md)

1. **Dlaczego zegar dla interfejsu źródłowo-synchronicznego generuje się rejestrem DDR z danymi 1 i 0, a nie wyprowadza bezpośrednio z sieci zegarowej?**

<details>
<summary>Odpowiedź</summary>

Bo wtedy zegar przechodzi przez identyczną ścieżkę jak dane — ten sam typ rejestru w bloku I/O, ten sam bufor wyjściowy — i ma prawie identyczne opóźnienie, niezależnie od rozmieszczenia i temperatury. Wyprowadzenie sieci zegarowej na pin daje inne opóźnienie niż ścieżka danych i nieprzewidywalny przekos. Dodatkowo narzędzie może wtedy poprawnie zdefiniować zegar generowany na pinie i przeanalizować wyjście względem niego.
</details>

2. **Dane DDR 200 Mb/s, t_SU = 0,6 ns, t_H = 0,4 ns, przekos płytki ±0,5 ns. Jaki jest zapas i gdzie ustawić zegar?**

<details>
<summary>Odpowiedź</summary>

UI = 5 ns (200 Mb/s → 100 MHz zegar, dwa bity na okres). Okno bez niepewności: 5 − 0,6 − 0,4 = 4,0 ns. Przekos ±0,5 ns zabiera 1,0 ns: zostaje 3,0 ns, czyli ±1,5 ns zapasu, jeśli zegar jest w środku okna — przesunięty względem zmiany danych o t_SU + (UI − t_SU − t_H)/2 = 0,6 + 2,0 = 2,6 ns (czyli o ok. UI/2 z poprawką na różnicę t_SU i t_H). Drgania zegara i danych trzeba jeszcze odjąć.
</details>

3. **Czym różni się interfejs źródłowo-synchroniczny od systemowo-synchronicznego?**

<details>
<summary>Odpowiedź</summary>

W systemowo-synchronicznym obie strony dostają zegar z jednego źródła wspólnego dla systemu, a dane przechodzą między nimi — budżet czasowy obejmuje opóźnienie zegara do obu układów i całą ścieżkę danych, więc przy dużych częstotliwościach przekos zegarów zjada okres. W źródłowo-synchronicznym nadajnik wysyła zegar razem z danymi, równoległymi ścieżkami; liczy się tylko przekos między nimi, nie bezwzględne opóźnienie — dlatego pozwala na znacznie większe szybkości. Kosztem jest osobna domena zegarowa w odbiorniku i przejście danych do zegara systemowego (FIFO).
</details>

### [22.03 — LVDS i serializacja (SERDES)](../modules/22-io-i-szybkie-interfejsy/22.03-lvds-i-serializacja-serdes.md)

1. **Na czym polega bitslip i dlaczego jest potrzebny?**

<details>
<summary>Odpowiedź</summary>

Deserializator dzieli strumień bitów na słowa co N bitów, ale nie wie, który bit jest pierwszym bitem słowa — zależy to od chwili startu licznika i opóźnień. Bitslip przesuwa granicę słowa o jeden bit (pominięcie jednego kroku licznika albo bitu w rejestrze). Automat wyrównania porównuje odebrane słowa ze znanym wzorcem treningowym albo słowem zegara ramki i wydaje bitslip, aż wzorzec pasuje kilka razy z rzędu; najwyżej N prób.
</details>

2. **Przetwornik ADC wysyła 14-bitowe próbki po parze LVDS z zegarem bitowym DCO i zegarem ramki FCO. Jak odebrać dane w FPGA?**

<details>
<summary>Odpowiedź</summary>

DCO (zwykle DDR) taktuje deserializatory wszystkich par albo służy jako wejście PLL generującego zegar bitowy i słowa z właściwą fazą (w środku bitu). FCO deserializuje się tak samo jak dane; przesuwa się granicę słowa bitslipem (dla wszystkich par jednocześnie), aż odebrane słowo FCO ma znaną postać (np. 7 jedynek i 7 zer). Wtedy dane w każdej parze są wyrównane do granicy próbki. Dodatkowo kalibruje się fazę (opóźnienia) każdej pary, jeśli przekos płytki jest znaczący, i przenosi słowa do zegara systemowego przez FIFO.
</details>

3. **Czym różni się miękki SERDES w MAX 10 od twardego w AMD 7-series?**

<details>
<summary>Odpowiedź</summary>

W twardym (OSERDESE2/ISERDESE2) rejestr przesuwny i dzielnik są w bloku I/O, pracują z zegarem bitowym z sieci I/O i osiągają 1–1,6 Gb/s; logika użytkownika widzi tylko słowo w zegarze słowa. W miękkim (MAX 10) rejestry przesuwne są w elementach logicznych przy bloku I/O, a IP i PLL zapewniają ich rozmieszczenie i zegary — osiągalna szybkość jest niższa (setki Mb/s), bo ogranicza ją logika ogólnego przeznaczenia. Funkcjonalnie (serializacja, bitslip) oba wyglądają podobnie.
</details>

### [22.04 — Transceivery wielogigabitowe: 8b/10b, 64b/66b i wyrównanie](../modules/22-io-i-szybkie-interfejsy/22.04-transceivery-wielogigabitowe-8b-10b-64b-66b-i.md)

1. **Po co kodowanie 8b/10b i jaki ma koszt?**

<details>
<summary>Odpowiedź</summary>

Zapewnia gęste zbocza (co najwyżej 5 jednakowych bitów z rzędu) dla odzyskiwania zegara, równowagę DC (łącze sprzężone pojemnościowo, brak wędrówki linii bazowej), znaki sterujące poza 256 danymi i przecinek do wyrównania granicy słowa, a do tego wykrywa część błędów. Koszt: 25 % pasma (10 bitów na 8) i trochę logiki. Dlatego szybsze standardy przeszły na 64b/66b i 128b/130b, gdzie narzut jest kilka razy mniejszy, a gęstość zboczy daje skrambler.
</details>

2. **Jak odbiornik znajduje granicę słowa w 8b/10b, a jak w 64b/66b?**

<details>
<summary>Odpowiedź</summary>

W 8b/10b nadajnik wysyła znaki z przecinkiem (K28.5); wzorzec 0011111/1100000 nie może wystąpić w danych ani na styku znaków, więc gdy odbiornik znajdzie go w strumieniu bitów, wie, gdzie zaczyna się znak, i przesuwa granicę. W 64b/66b nie ma przecinka — odbiornik sprawdza kolejne pozycje: na właściwej pierwsze dwa bity każdego bloku to zawsze 01 albo 10; jeśli przez kilkadziesiąt bloków na danej pozycji nie ma błędnego nagłówka, granica jest znaleziona (inaczej przesuwa się o bit).
</details>

3. **Dwie płytki mają generatory 156,25 MHz ±100 ppm. Co trzeba zrobić, żeby przesyłać dane bez przerwy między nimi?**

<details>
<summary>Odpowiedź</summary>

Zegary mogą różnić się do 200 ppm, czyli o jeden znak na 5000. Odbiornik pracuje w zegarze odzyskanym z danych, a dalej dane muszą trafić do zegara lokalnego — przez bufor elastyczny z korekcją zegara. Nadajnik musi co określoną liczbę znaków (mniej niż 5000, z zapasem) wstawiać znaki wypełnienia, które bufor może usunąć albo powielić, żeby utrzymać zapełnienie. Protokoły to definiują (SKP w PCIe, IDLE w Ethernecie); w łączu własnym trzeba to zaprojektować albo użyć wspólnego zegara referencyjnego.
</details>

### [22.05 — Przegląd protokołów: PCIe, JESD204, Aurora, SATA](../modules/22-io-i-szybkie-interfejsy/22.05-przeglad-protokolow-pcie-jesd204-aurora-sata.md)

1. **Dlaczego PCIe ma ponawianie pakietów, a JESD204 nie?**

<details>
<summary>Odpowiedź</summary>

PCIe przenosi transakcje między systemami (zapisy do pamięci, rejestrów), gdzie zgubiony albo przekłamany pakiet jest niedopuszczalny — warstwa łącza danych dokłada CRC, numery sekwencji, ACK/NAK i bufor ponowień, za cenę opóźnienia i logiki. JESD204 przenosi ciągły strumień próbek przetwornika: spóźniona, ponowiona próbka byłaby bezużyteczna, a stałe, deterministyczne opóźnienie jest ważniejsze niż poprawianie pojedynczych błędów. Łącze projektuje się więc na odpowiednio niski BER, a nie na ponawianie.
</details>

2. **Co daje SYSREF w JESD204B podklasy 1?**

<details>
<summary>Odpowiedź</summary>

SYSREF to sygnał rozprowadzany synchronicznie do wszystkich przetworników i do FPGA, wyznaczający wspólny początek wieloramki lokalnej (LMFC) we wszystkich urządzeniach. Dzięki temu opóźnienie od próbkowania do danych w FPGA jest stałe i znane po każdym uruchomieniu (deterministyczne) i jednakowe dla wszystkich przetworników — co pozwala synchronizować wiele ADC/DAC z dokładnością do próbki. Wymaga spełnienia czasów t_SU/t_H SYSREF względem zegarów urządzeń.
</details>

3. **Potrzebujesz przesyłać 2 GB/s z FPGA do komputera. Jakie łącze PCIe wybierzesz?**

<details>
<summary>Odpowiedź</summary>

Gen3 ×4 daje ok. 3,94 GB/s po kodowaniu, a po nagłówkach przy ładunku 256 B ok. 3,5 GB/s — zapas prawie dwukrotny, typowy wybór. Gen2 ×8 (4 GB/s po kodowaniu) też wystarczy, ale zużywa dwa razy więcej transceiverów. Gen4 ×2 — jeśli układ obsługuje Gen4. Do tego DMA z dużymi transferami (scatter-gather) i bufor po stronie FPGA pokrywający chwilowe przestoje hosta.
</details>

### [22.06 — FPGA na płytce PCB: zasilanie, sekwencjonowanie i planowanie pinów](../modules/22-io-i-szybkie-interfejsy/22.06-fpga-na-plytce-pcb-zasilanie-sekwencjonowanie-i.md)

1. **Jak przygotujesz przydział pinów FPGA dla nowej płytki?**

<details>
<summary>Odpowiedź</summary>

Zbieram listę sygnałów z wymaganiami (standard, szybkość, różnicowe, zegary), przydzielam banki według VCCIO i VREF, zegary umieszczam na dedykowanych pinach zegarowych, pinouty pamięci i transceiverów biorę z generatorów IP, rozkładam szerokie magistrale ze względu na SSN i sąsiedztwo, uwzględniam piny konfiguracji i dwufunkcyjne. Potem tworzę projekt z samymi portami i przypisaniami i kompiluję go — narzędzie sprawdza reguły banków i par. Pinout bez błędów eksportuję do projektanta PCB, przeglądam schemat z *Pin Connection Guidelines* i zostawiam rezerwę oraz punkty testowe.
</details>

2. **Po co tyle kondensatorów przy FPGA i jak dobrać ich liczbę?**

<details>
<summary>Odpowiedź</summary>

Rdzeń zmienia pobór prądu w nanosekundach, a regulator reaguje w mikrosekundach — energię na krótkie skoki dostarczają kondensatory, każdy skuteczny w swoim zakresie częstotliwości (duże przy regulatorze, ceramiczne µF w pobliżu, 0,1 µF i mniejsze przy pinach, płaszczyzny i kondensatory w obudowie dla najwyższych). Dobiera się je tak, by impedancja sieci zasilania była niższa od impedancji docelowej (dopuszczalny spadek napięcia / skok prądu) w całym paśmie, korzystając z narzędzi PDN producenta i zaleceń dla danego układu.
</details>

3. **Czym różni się MAX 10 jedno- i dwuzasilaniowy?**

<details>
<summary>Odpowiedź</summary>

Wersja jednozasilaniowa ma wewnętrzny regulator i wymaga tylko jednego napięcia 3,0/3,3 V (plus VCCIO), co upraszcza płytkę, ale pobiera więcej mocy (straty regulatora) i ma ograniczenia wydajności. Dwuzasilaniowa (D, jak 10M50DAF484 na DECA) wymaga zewnętrznego 1,2 V dla rdzenia i 2,5 V dla VCCA, ale jest wydajniejsza i oszczędniejsza energetycznie; zakres wejściowy ADC też się różni (2,5 V w dwuzasilaniowej, [20.06](../modules/20-interfejsy-szeregowe/20.06-wbudowany-przetwornik-adc-w-max-10.md)).
</details>

## 23 — Pamięci zewnętrzne

### [23.01 — SDRAM i DDR: jak działają, odświeżanie i opóźnienia](../modules/23-pamieci-zewnetrzne/23.01-sdram-i-ddr-jak-dzialaja-odswiezanie-i.md)

1. **Co dzieje się przy odczycie z DRAM, gdy w banku otwarty jest inny wiersz? Ile to trwa?**

<details>
<summary>Odpowiedź</summary>

Konflikt wiersza: kontroler musi zamknąć otwarty wiersz (PRECHARGE, czas tRP), otworzyć nowy (ACTIVATE, tRCD do pierwszego READ), wydać READ i odczekać CL do danych. Dla DDR3-1600 to ok. 13,75 + 13,75 + 13,75 ≈ 41 ns plus czas burstu — trzy razy dłużej niż trafienie w otwarty wiersz (samo CL). Kontroler ukrywa część tego czasu, otwierając wiersze w innych bankach równolegle.
</details>

2. **Po co DRAM odświeżanie i ile kosztuje?**

<details>
<summary>Odpowiedź</summary>

Informacja to ładunek w kondensatorze komórki, który ucieka przez upływność — w ciągu dziesiątek milisekund zmieniłby się w nieczytelny. Każdy wiersz trzeba odczytać i zapisać z powrotem co 64 ms (przy wyższej temperaturze częściej). Kontroler wydaje rozkaz REFRESH średnio co 7,8 µs, a pamięć jest wtedy niedostępna przez tRFC (100–350 ns), czyli ok. 2–5 % czasu; dodatkowo wszystkie wiersze muszą być wcześniej zamknięte.
</details>

3. **Dlaczego DDR4-3200 nie ma dwa razy mniejszego opóźnienia dostępu niż DDR3-1600?**

<details>
<summary>Odpowiedź</summary>

Bo opóźnienia CL, tRCD, tRP są wyznaczone przez rdzeń pamięci (komórki, wzmacniacze odczytu, dekodery), który nie przyspieszył — wynoszą ok. 13–15 ns w obu generacjach. Wyższa szybkość interfejsu bierze się z prefetchu i szybszego I/O: w taktach CL jest dwa razy większe (np. 22 zamiast 11), ale w nanosekundach podobne. Rośnie przepustowość przy długich transferach, nie szybkość pojedynczego dostępu.
</details>

### [23.02 — Kontroler DDR3 na MAX 10 (UniPHY)](../modules/23-pamieci-zewnetrzne/23.02-kontroler-ddr3-na-max-10-uniphy.md)

1. **Co robi PHY kontrolera DDR, a co sam kontroler?**

<details>
<summary>Odpowiedź</summary>

Kontroler zamienia żądania z magistrali (odczyt/zapis pod adresem) na rozkazy DDR: otwiera i zamyka wiersze, przestawia kolejność, żeby zwiększyć liczbę trafień, pilnuje parametrów czasowych, wstawia odświeżanie, kalibrację ZQ i sterowanie ODT. PHY to warstwa fizyczna: rejestry DDR i linie opóźniające w blokach I/O, generowanie DQS i zegara pamięci, odbiór danych ze strobem z przesunięciem do środka okna, ścieżka do domeny kontrolera, a przy starcie — kalibracja odczytu i zapisu. Łączy je interfejs AFI (u AMD: odpowiednik DFI).
</details>

2. **Dlaczego interfejs użytkownika kontrolera DDR3 pracuje na połowie częstotliwości pamięci?**

<details>
<summary>Odpowiedź</summary>

Bo logika ogólnego przeznaczenia w FPGA nie zamknie czasowo częstotliwości pamięci (300–1200 MHz), a PHY i tak przenosi dane w blokach I/O z dużą szybkością. Interfejs half rate (albo quarter rate w szybszych układach) przesyła na każdy takt wolniejszego zegara dwa (cztery) razy szersze słowo — przepustowość jest ta sama, a logika ma 2–4 razy więcej czasu na takt. Kosztem jest większe opóźnienie i szersze magistrale.
</details>

3. **Po uruchomieniu na płytce `local_cal_fail = 1`. Jak szukasz przyczyny?**

<details>
<summary>Odpowiedź</summary>

Sprawdzam po kolei: zasilanie pamięci i VREF/VTT, zegar referencyjny i blokadę PLL, reset; zgodność parametrów kości (szerokość, CL, CWL, tryb) z rzeczywistą pamięcią; przypisania pinów ze skryptu IP (szczególnie grupy DQ/DQS i polaryzacja zegara); parametry płytki; potem EMIF Debug Toolkit — na którym etapie kalibracji i w której grupie bajtowej jest błąd. Pojedyncza grupa wskazuje na płytkę (lutowanie, ścieżka), wszystkie — na parametry, zegar albo zasilanie. Obniżenie częstotliwości to szybki test, czy problem jest marginesem czasowym.
</details>

### [23.03 — Pamięci QSPI flash i HyperRAM](../modules/23-pamieci-zewnetrzne/23.03-pamieci-qspi-flash-i-hyperram.md)

1. **Czym różnią się tryby 1-1-1, 1-1-4 i 1-4-4 i ile dają przyspieszenia?**

<details>
<summary>Odpowiedź</summary>

Liczby mówią, ile linii przenosi rozkaz, adres i dane. 1-1-1 — wszystko szeregowo, 1-1-4 — dane na 4 liniach (4 razy krócej), 1-4-4 — także adres na 4 liniach (6 zamiast 24 cykli). Przyspieszenie całej transakcji zależy od jej długości: rozkaz i cykle puste się nie skracają, więc dla 256 B 1-1-4 daje ok. 3,8× (w testbenchu 8324 vs 2212 taktów), a dla 4 bajtów — niewiele. Tryb quad wymaga bitu QE.
</details>

2. **Jak zapisać 10 bajtów pod adres 0x1000 w pamięci flash SPI?**

<details>
<summary>Odpowiedź</summary>

Jeżeli sektor nie jest skasowany: WREN (06h), SECTOR ERASE 20h z adresem 0x1000, odpytywanie READ STATUS (05h) aż WIP = 0 (dziesiątki–setki ms). Potem WREN, PAGE PROGRAM 02h z adresem 0x1000 i 10 bajtami (w obrębie jednej strony 256 B), odpytywanie WIP (~1 ms). Kasowanie usuwa cały sektor 4 KB — jeśli są w nim inne dane, trzeba je wcześniej odczytać i zapisać z powrotem.
</details>

3. **Kiedy wybrać HyperRAM zamiast DDR3?**

<details>
<summary>Odpowiedź</summary>

Gdy potrzeba kilku–kilkudziesięciu MB i do kilkuset MB/s, a liczy się liczba pinów, prostota płytki i zasoby FPGA: 12 sygnałów zamiast ok. 45, brak kalibracji i zewnętrznego odświeżania, prosty kontroler bez IP producenta, mniejszy pobór. DDR3 wybiera się przy większej pojemności (setki MB–GB) i przepustowości (GB/s) albo gdy kontroler jest twardym blokiem w układzie.
</details>

### [23.04 — Arbitraż dostępu do pamięci i DMA](../modules/23-pamieci-zewnetrzne/23.04-arbitraz-dostepu-do-pamieci-i-dma.md)

1. **Na czym polega zagłodzenie i jak mu zapobiega round-robin?**

<details>
<summary>Odpowiedź</summary>

Zagłodzenie: master nigdy nie dostaje dostępu, bo zawsze zgłasza się ktoś o wyższym priorytecie. W round-robin po obsłużeniu mastera *i* najwyższy priorytet przechodzi na *i+1*, więc każdy zgłaszający się master zostanie obsłużony najpóźniej po N−1 transferach innych. W teście trzech masterów zgłaszających się stale dostało po ~600 transferów.
</details>

2. **Pamięć ma opóźnienie odczytu 10 taktów. Jak zbudować DMA, które kopiuje z szybkością 1 słowo na 2 takty?**

<details>
<summary>Odpowiedź</summary>

Odczyty potokowe: wystawiać kolejne odczyty bez czekania na dane, mając co najmniej ~10 odczytów w locie, i bufor (FIFO) na tyle słów, ile może być w locie i jeszcze niezapisanych. Odczyt wolno wydać tylko, gdy w buforze jest miejsce na jego odpowiedź (licznik słów w locie + w buforze ≤ głębokość). Zapisy przeplatają się z odczytami; z jednym portem daje to 2 takty na słowo, z osobnymi portami odczytu i zapisu — 1.
</details>

3. **Jak arbiter wie, któremu masterowi oddać dane odczytu, skoro slave przyjmuje kilka odczytów naraz?**

<details>
<summary>Odpowiedź</summary>

Slave Avalon-MM zwraca dane w kolejności przyjęcia rozkazów, więc arbiter przy każdym przyjętym odczycie zapisuje numer mastera do kolejki FIFO, a przy każdym `readdatavalid` zdejmuje numer z czoła i kieruje odpowiedź do tego mastera. Gdy kolejka jest pełna, nie przyjmuje nowych odczytów. W AXI zamiast tego służą identyfikatory transakcji (ID) — odpowiedzi z różnymi ID mogą wracać w innej kolejności.
</details>

### [23.05 — Karta microSD: tryb SPI i tryb SD](../modules/23-pamieci-zewnetrzne/23.05-karta-microsd-tryb-spi-i-tryb-sd.md)

1. **Opisz inicjalizację karty SD w trybie SPI.**

<details>
<summary>Odpowiedź</summary>

Zegar 100–400 kHz, co najmniej 74 takty z CS = 1. CMD0 z CS = 0 — karta wchodzi w tryb SPI i odpowiada R1 = 0x01. CMD8 z argumentem 0x1AA — karta v2 odsyła echo (inaczej starsza karta). Potem pętla CMD55 + ACMD41 z bitem HCS, aż R1 = 0x00 (do ok. 1 s). CMD58 odczytuje OCR: bit CCS mówi, czy to SDHC/SDXC (adresowanie blokami), czy SDSC (bajtami — wtedy jeszcze CMD16 512). Na koniec zegar w górę, do 25 MHz. W testbenchu: 11 rozkazów i 2,4 ms dla SDHC.
</details>

2. **Czym różni się adresowanie kart SDSC i SDHC i co się stanie przy pomyłce?**

<details>
<summary>Odpowiedź</summary>

SDSC (do 2 GB) przyjmuje w CMD17/CMD24 adres w bajtach, SDHC/SDXC — numer bloku 512 B. Typ rozpoznaje się po bicie CCS w OCR (CMD58). Pomyłka nie daje błędu: na SDHC adres bajtowy blok × 512 wskazuje blok 512 razy dalej (albo poza pojemnością → błąd adresu), na SDSC numer bloku czyta niewyrównany fragment z początku karty. Dlatego testbench sprawdza obie karty z blokami 5 i 1000.
</details>

3. **Dlaczego karta działa w trybie SPI z 1 linią danych, skoro ma 4, i ile się na tym traci?**

<details>
<summary>Odpowiedź</summary>

Tryb SPI jest częścią specyfikacji dla prostych hostów (mikrokontrolery): jedna linia danych w każdą stronę, prosty protokół bajtowy. Tryb natywny SD używa linii CMD i 4 linii DAT, z osobnym CRC16 na linię, i zegarów do 50 MHz (high speed) albo wyższych w UHS. SPI przy 25 MHz daje do ~3 MB/s, tryb SD 4-bitowy przy 50 MHz — 25 MB/s; do rejestracji danych z dużą szybkością potrzebny jest więc tryb natywny i odczyt/zapis wielu bloków (CMD18/CMD25).
</details>

## 24 — Wideo i grafika

### [24.01 — Sygnał wideo: taktowanie, wygaszanie i zegar piksela](../modules/24-wideo-i-grafika/24.01-sygnal-wideo-taktowanie-wygaszanie-i-zegar.md)

1. **Skąd bierze się 25,175 MHz dla 640×480 przy 60 Hz?**

<details>
<summary>Odpowiedź</summary>

Z całkowitej liczby pikseli w ramce razy częstotliwość odświeżania: linia ma 800 taktów (640 aktywnych + 16 przedsionka + 96 impulsu + 48 tylnego progu), ramka 525 linii (480 + 10 + 2 + 33), 800 × 525 = 420 000 taktów na ramkę, × 59,94 Hz ≈ 25,175 MHz. Wartość pochodzi z oryginalnego VGA, w którym częstotliwość linii (31,469 kHz) była dwukrotnością telewizyjnej NTSC.
</details>

2. **Po co cyfrowemu monitorowi wygaszanie, skoro nie ma wiązki do zawrócenia?**

<details>
<summary>Odpowiedź</summary>

Częściowo z kompatybilności (te same tryby co monitory CRT, ta sama elektronika skalerów), a częściowo dlatego, że w wygaszaniu przesyła się inne dane: HDMI w okresach wysp danych (*data islands*) przenosi dźwięk i ramki informacyjne (InfoFrame), DisplayPort — dane dodatkowe. Gdzie to niepotrzebne, stosuje się skrócone wygaszanie (CVT-RB), co zmniejsza wymagany zegar piksela.
</details>

3. **Jak przetworzyć 1080p60 w FPGA, którego logika nie zamknie czasowo 148,5 MHz?**

<details>
<summary>Odpowiedź</summary>

Przetwarzać dwa (albo cztery) piksele na takt przy połowie (ćwiartce) zegara: generator taktowania liczy pary pikseli, potok i bufory są dwa razy szersze, a serializacja do pełnej szybkości odbywa się w nadajniku (zewnętrznym albo w rejestrach DDR/serializatorach I/O). Druga możliwość — tryb z reduced blanking, który obniża zegar przy tej samej rozdzielczości.
</details>

### [24.02 — HDMI i DVI: kodowanie TMDS i nadajnik ADV7513 na DECA](../modules/24-wideo-i-grafika/24.02-hdmi-i-dvi-kodowanie-tmds-i-nadajnik-adv7513-na.md)

1. **Po co TMDS koduje 8 bitów na 10 i co robią bity 8 i 9?**

<details>
<summary>Odpowiedź</summary>

Żeby strumień nadawał się do transmisji szeregowej z odtwarzaniem zegara przez łącze sprzężone pojemnościowo: mało zmian (mniej zakłóceń elektromagnetycznych i przesłuchów), zrównoważona liczba jedynek i zer (brak składowej stałej) i możliwość rozpoznania granic symboli. Bit 8 mówi, czy przy minimalizacji zmian użyto XOR czy XNOR; bit 9 — czy bity 7..0 odwrócono, żeby wyrównać bilans jedynek i zer śledzony licznikiem cnt. Znaki sterujące w wygaszaniu mają dużo zmian (7–8) i są nie do pomylenia z danymi (≤ 5).
</details>

2. **Czym różni się sygnał HDMI od DVI, skoro złącze HDMI–DVI działa bez elektroniki?**

<details>
<summary>Odpowiedź</summary>

Warstwa fizyczna (TMDS) i kodowanie pikseli są wspólne, więc obraz przechodzi. HDMI dodaje w wygaszaniu okresy wysp danych z dźwiękiem i ramkami InfoFrame (kodowanie TERC4, sumy kontrolne BCH), preambuły i pasma ochronne przed okresami danych, a także YCbCr, głębszy kolor, CEC i HDCP. Nadajnik HDMI podłączony do monitora DVI powinien przejść w tryb DVI (na podstawie EDID), bo monitor DVI nie zna wysp danych.
</details>

3. **Monitor po podłączeniu do płytki z ADV7513 pokazuje „brak sygnału”. Co sprawdzasz?**

<details>
<summary>Odpowiedź</summary>

Najpierw konfigurację: czy transakcje I2C dostają ACK (adres 0x72, zasilanie i reset nadajnika), czy zapisano 0x41 i rejestry stałe, czy HPD jest widziany (0x42) — i czy konfiguracja jest powtarzana po podłączeniu kabla. Potem sygnał wejściowy: zegar piksela na pinie, poprawne taktowanie (HS/VS/DE, szerokości impulsów), format wejścia zgodny z 0x15/0x16. Na koniec tryb: czy monitor przyjmuje daną rozdzielczość i odświeżanie (np. 640×480 przy 59,5 zamiast 59,94 Hz) i czy tryb HDMI/DVI pasuje do odbiornika.
</details>

### [24.03 — Grafika generowana: sprite'y, tekst i linie](../modules/24-wideo-i-grafika/24.03-grafika-generowana-sprite-y-tekst-i-linie.md)

1. **Jak wyświetlić tekst 80×30 znaków na 640×480 bez bufora ramki?**

<details>
<summary>Odpowiedź</summary>

Pamięcią znaków (2400 bajtów: kod ASCII na komórkę 8×16) i ROM czcionki (256 znaków × 16 wierszy × 8 bitów = 4 KB). Dla piksela (x, y): komórka (x/8, y/16), adres = wiersz·80 + kolumna → kod znaku → adres w ROM = kod·16 + (y mod 16) → bajt wiersza czcionki → bit (7 − x mod 8). Dwa odczyty pamięci, więc 2 takty opóźnienia, które trzeba wyrównać z synchronizacją i pozostałymi warstwami. Razem ok. 6,5 KB zamiast 300 KB bufora ramki.
</details>

2. **Wyjaśnij algorytm Bresenhama i dlaczego nadaje się do sprzętu.**

<details>
<summary>Odpowiedź</summary>

Idzie po odcinku krokami jednopikselowymi w osi głównej i decyduje o kroku w osi pobocznej na podstawie całkowitoliczbowego błędu, który mierzy odległość od idealnej prostej. W wersji ogólnej: e = dx + dy, w każdym kroku e2 = 2e, krok w x gdy e2 ≥ dy, krok w y gdy e2 ≤ dx, z odpowiednią aktualizacją e. Tylko dodawania, porównania i przesunięcie o bit — bez mnożenia, dzielenia i liczb ułamkowych — więc w FPGA daje jeden punkt na takt przy niewielkiej logice, a wynik jest dokładny (błąd ≤ ½ piksela).
</details>

3. **Masz trzy warstwy o opóźnieniach 1, 2 i 4 takty. Jak je złożysz?**

<details>
<summary>Odpowiedź</summary>

Opóźniam wyjścia warstw 1- i 2-taktowej rejestrami przesuwnymi do 4 taktów (o 3 i 2 rejestry), sygnały DE/HS/VS też o 4 takty, i dopiero wtedy mikser wybiera kolor według priorytetu. Alternatywnie wysuwam wcześniej współrzędne dla wolniejszej warstwy (podaję jej x + 3), ale to komplikuje brzegi linii; opóźnianie szybszych warstw jest prostsze i pewniejsze.
</details>

### [24.04 — Bufor ramki w DDR3](../modules/24-wideo-i-grafika/24.04-bufor-ramki-w-ddr3.md)

1. **Na czym polega rozdarcie obrazu i jak mu zapobiega podwójne buforowanie?**

<details>
<summary>Odpowiedź</summary>

Rozdarcie powstaje, gdy obraz w ramce wyświetlanej zmienia się w trakcie jej skanowania: górna część ekranu pokazuje stary obraz, dolna nowy, więc poruszające się obiekty są „przecięte” poziomą linią. Przy podwójnym buforowaniu autor rysuje zawsze do ramki niewyświetlanej, a zamiana (wybór adresu bazowego czytnika) następuje tylko w wygaszaniu pionowym, między ramkami. Autor po zgłoszeniu zamiany czeka na jej wykonanie, bo dopiero wtedy stara ramka przestaje być czytana.
</details>

2. **Jak dobrać wielkość bufora po stronie wyświetlania?**

<details>
<summary>Odpowiedź</summary>

Tak, żeby pokrył najdłuższy czas, przez który pamięć może nie dostarczać danych, przy tempie zużycia zegara piksela: opóźnienie pierwszego słowa, przerwa na odświeżanie DRAM (np. tRFC co 7,8 µs), obsługa innych masterów (bursty zapisu, procesor) i przełączenia wierszy. Przykład: 1080p (148,5 Mpix/s × 4 B ≈ 600 MB/s w obszarze aktywnym) i maks. 2 µs przerwy → co najmniej ok. 1,2 KB, czyli ponad 300 pikseli; w praktyce bufor jednej–dwóch linii daje zapas i upraszcza skalowanie. Wielkość weryfikuje się licznikiem niedoborów pod pełnym obciążeniem.
</details>

3. **Jak przekazać informację „zaczęła się nowa linia” z domeny piksela do domeny pamięci?**

<details>
<summary>Odpowiedź</summary>

Jako zmianę bitu przełączanego (toggle): w domenie piksela bit zmienia stan przy każdym zdarzeniu, w domenie pamięci przechodzi przez synchronizator dwu-/trzyprzerzutnikowy, a XOR dwóch ostatnich stopni daje impuls. Działa, bo zdarzenia są dużo rzadsze niż oba zegary (co linię). Numer linii nie jest przesyłany — domena pamięci liczy zdarzenia sama; gdyby trzeba było przesłać wartość wielobitową, użyłbym kodu Graya (dla licznika) albo FIFO dwuzegarowego.
</details>

### [24.05 — Kamera MIPI CSI-2 na DECA](../modules/24-wideo-i-grafika/24.05-kamera-mipi-csi-2-na-deca.md)

1. **Czym różnią się tryby HS i LP w D-PHY i po co są dwa?**

<details>
<summary>Odpowiedź</summary>

HS to szybka transmisja różnicowa o małej amplitudzie (ok. 200 mV, setki Mb/s – Gb/s na pas) z terminacją 100 Ω — dla danych obrazu. LP to wolne (do 10 Mb/s) sygnały jednoprzewodowe 1,2 V bez terminacji, o bardzo małym poborze — do sygnalizacji stanów (np. przejścia na HS, koniec transmisji, tryb uśpienia) i komunikacji pomocniczej. Dzięki temu pas między pakietami nie zużywa prądu na terminacji, a odbiornik dostaje jednoznaczny znak początku transmisji HS.
</details>

2. **Jak wygląda pakiet długi CSI-2 i jak odbiornik wie, gdzie się kończy?**

<details>
<summary>Odpowiedź</summary>

Czterobajtowy nagłówek: Data ID (kanał wirtualny i typ danych, np. RAW10), 16-bitowa liczba bajtów danych (*word count*) i ECC chroniący te 24 bity; potem dokładnie *word count* bajtów danych i dwubajtowe CRC-16. Odbiornik sprawdza i ewentualnie poprawia nagłówek kodem ECC, a potem odlicza bajty według word count — dlatego błąd w nagłówku jest groźny i stąd ECC zamiast samej parzystości. Po stopce nadajnik kończy transmisję HS i pas wraca do LP-11.
</details>

3. **FPGA nie ma bloku MIPI D-PHY. Jak odebrać obraz z kamery CSI-2?**

<details>
<summary>Odpowiedź</summary>

Trzy drogi: zewnętrzny układ pomostowy (np. konwerter CSI-2 → równoległy, jak na płytkach z TC358748), bierna sieć rezystorów do wejść FPGA (AN 754: tor HS na wejście LVDS z terminacją, tor LP na wejścia 1,2 V; ok. 500–800 Mb/s na pas) albo FPGA z twardym D-PHY (nowsze rodziny). W drugim przypadku logika CSI-2 (wyrównanie, scalanie pasów, ECC, CRC) jest miękka; trzeba pilnować standardów I/O banku i długości ścieżek.
</details>

### [24.06 — Przetwarzanie obrazu strumieniowo: bufory linii i filtry 3×3](../modules/24-wideo-i-grafika/24.06-przetwarzanie-obrazu-strumieniowo-bufory-linii.md)

1. **Ile pamięci potrzebuje filtr 5×5 dla obrazu 1920×1080, 8 bitów na piksel, i jakie ma opóźnienie?**

<details>
<summary>Odpowiedź</summary>

Cztery bufory linii po 1920 × 8 bitów = 61 440 bitów (przy sposobie „pełnej linii” — 2200 pozycji, 70 400 bitów), czyli ok. 8–9 bloków M9K, plus 25 rejestrów 8-bitowych okna. Środek okna jest dwie linie i dwa piksele za najnowszym pikselem, więc opóźnienie to ok. 2 linie (2 × 2200 taktów) plus kilka taktów potoku obliczeń — przy 148,5 MHz ok. 30 µs. Bufora ramki nie potrzeba.
</details>

2. **Jak obsłużyć brzegi obrazu w filtrze strumieniowym?**

<details>
<summary>Odpowiedź</summary>

Najprościej zerami: jeśli linie opóźniające obejmują wygaszanie i piksele wygaszania są zerowane, sąsiedzi spoza obrazu automatycznie są zerami. Lepsze dla wielu filtrów jest powielanie skrajnego piksela albo odbicie — wtedy na podstawie pozycji (pierwsza/ostatnia kolumna, pierwszy/ostatni wiersz) multipleksery podstawiają w oknie właściwe piksele zamiast sąsiadów. Można też obciąć wynik (nie wyświetlać brzegowego piksela) — obraz wyjściowy jest wtedy mniejszy o (N − 1) pikseli.
</details>

3. **Dlaczego Sobel w sprzęcie liczy |Gx| + |Gy| zamiast pierwiastka z sumy kwadratów?**

<details>
<summary>Odpowiedź</summary>

Bo daje podobną informację (siłę gradientu) bez mnożarek i bez pierwiastka — tylko wartości bezwzględne i dodawanie, czyli kilka sumatorów w jednym takcie. Przybliżenie zawyża wynik najwyżej o ok. 41 % dla gradientu ukośnego (dla poziomego i pionowego jest dokładne), co przy progowaniu krawędzi zwykle nie przeszkadza. Gdy potrzeba dokładnej wartości albo kierunku, używa się tablic, algorytmu CORDIC albo przybliżenia max + ½ min.
</details>

## 25 — Audio i Ethernet

### [25.01 — I²S i kodek audio na DECA](../modules/25-audio-i-ethernet/25.01-i2s-i-kodek-audio-na-deca.md)

1. **Jakie zegary potrzebne są do pracy kodeka audio przez I²S i jak są ze sobą powiązane?**

<details>
<summary>Odpowiedź</summary>

WCLK (LRCLK) o częstotliwości próbkowania fs, BCLK = fs × liczba bitów w ramce (np. 64 · fs) i zwykle MCLK — zegar przetworników, wielokrotność fs (256 · fs, 512 · fs) albo wejście PLL kodeka. Wszystkie muszą pochodzić z jednego źródła albo być zsynchronizowane, a dzielniki wewnątrz kodeka muszą dawać z MCLK dokładnie fs. Inaczej przetwornik i interfejs „rozjeżdżają się” i co jakiś czas próbka jest gubiona albo powtarzana (trzask).
</details>

2. **Czym różni się format I²S od left-justified?**

<details>
<summary>Odpowiedź</summary>

W I²S najstarszy bit próbki pojawia się jeden takt BCLK po zmianie WCLK, a WCLK = 0 oznacza kanał lewy. W left-justified MSB pojawia się razem ze zmianą WCLK, a polaryzacja WCLK jest zwykle odwrotna (1 — lewy). Pomylenie formatów przesuwa dane o bit: próbka jest dwukrotnie mniejsza albo większa i z przekłamanym znakiem — dźwięk zniekształcony, ale słyszalny, co utrudnia diagnozę.
</details>

3. **FPGA ma być masterem I²S. Jak zrealizujesz BCLK, żeby nie mieć problemów z analizą czasową?**

<details>
<summary>Odpowiedź</summary>

BCLK nie jako zegar logiki, tylko jako sygnał danych: licznik w domenie szybszego zegara (tu 12,5 MHz) i rejestry wyjściowe dla BCLK, WCLK i danych ustawiane razem. Dane zmieniam w fazie odpowiadającej opadającemu BCLK, odbiór próbkuję w fazie po narastającym — w obu przypadkach z zapasem wielu nanosekund, więc wystarczą zwykłe ograniczenia (albo false path przy tak wolnym interfejsie). Logika przetwarzania pracuje w tej samej domenie i dostaje impuls „nowa ramka” zamiast zegara WCLK.
</details>

### [25.02 — Przetwarzanie dźwięku w czasie rzeczywistym](../modules/25-audio-i-ethernet/25.02-przetwarzanie-dzwieku-w-czasie-rzeczywistym.md)

1. **Dlaczego filtr IIR wysokiego rzędu implementuje się jako kaskadę biquadów?**

<details>
<summary>Odpowiedź</summary>

Bo bieguny wielomianu wysokiego rzędu są bardzo wrażliwe na błędy współczynników: mała kwantyzacja współczynnika w postaci bezpośredniej przesuwa wszystkie bieguny i może wyprowadzić któryś poza okrąg jednostkowy (niestabilność). W kaskadzie każda sekcja realizuje jedną parę biegunów — błąd kwantyzacji wpływa tylko na nią, a zakresy liczb wewnątrz sekcji łatwiej kontrolować (skalowanie między sekcjami). Przy okazji każda sekcja ma ten sam sprzęt, więc łatwo ją multipleksować w czasie.
</details>

2. **Masz zegar 50 MHz i 8 kanałów audio 48 kHz, każdy z 10 sekcjami biquad. Ile mnożarek potrzebujesz?**

<details>
<summary>Odpowiedź</summary>

Na próbkę przypada 50 MHz / 48 kHz ≈ 1041 taktów. Potrzeba 8 × 10 × 5 = 400 mnożeń na okres próbki, więc jedna mnożarka wystarczy z zapasem (400 < 1041), jeśli uda się ją zasilać co takt (stany sekcji w pamięci, potok: odczyt stanu, mnożenie, akumulacja, zapis). Dla bezpieczeństwa i prostszego sterowania można użyć dwóch (po 4 kanały). To typowa zaleta FPGA w audio: zasoby liczy się w mnożeniach na sekundę, nie w liczbie filtrów.
</details>

3. **Co to znaczy, że współczynniki są w formacie Q2.16, i jak zamienić wynik mnożenia z powrotem na próbkę?**

<details>
<summary>Odpowiedź</summary>

Liczba 18-bitowa ze znakiem interpretowana jako wartość całkowita podzielona przez 2¹⁶: 2 bity na znak i część całkowitą (zakres [−2, 2)), 16 bitów ułamka. Iloczyn próbki całkowitej i współczynnika Q2.16 ma 16 bitów ułamkowych, więc po zsumowaniu iloczynów wynik trzeba przesunąć o 16 bitów w prawo — najpierw dodając 2¹⁵ (zaokrąglenie do najbliższej), potem nasycić do zakresu próbki (24 bity), zanim trafi do rejestru wyjścia i do linii opóźniającej filtra.
</details>

### [25.03 — Ethernet 10/100: MII, PHY i MAC](../modules/25-audio-i-ethernet/25.03-ethernet-10-100-mii-phy-i-mac.md)

1. **Dlaczego ramka Ethernet ma co najmniej 64 bajty?**

<details>
<summary>Odpowiedź</summary>

Z powodu CSMA/CD w Ethernecie współdzielonym (koncentratory, kabel koncentryczny): nadawca wykrywa kolizję tylko w trakcie nadawania, więc ramka musi trwać co najmniej tyle, ile podwójny czas propagacji przez największą dopuszczalną sieć — 512 czasów bitu, czyli 64 bajty. W sieciach przełączanych z pełnym dupleksem kolizji nie ma, ale minimum zostało dla zgodności; krótsze dane uzupełnia się zerami, a odbiornik odrzuca krótsze ramki (*runt*).
</details>

2. **Jak odbiornik sprawdza FCS, nie wiedząc, gdzie kończą się dane?**

<details>
<summary>Odpowiedź</summary>

Liczy CRC po wszystkich bajtach ramki łącznie z FCS — dla poprawnej ramki wynik (bez końcowej negacji) jest zawsze ten sam, 0xDEBB20E3 (reszta „magiczna”). Koniec ramki sygnalizuje PHY (RX_DV = 0), więc odbiornik po prostu sprawdza rejestr CRC w tym momencie. Żeby nie przekazać dalej bajtów FCS, MAC opóźnia strumień o 4 bajty i w chwili końca ramki odrzuca to, co zostało w opóźnieniu.
</details>

3. **Czym różnią się MII, RMII i RGMII?**

<details>
<summary>Odpowiedź</summary>

MII: 4 bity w każdą stronę, osobne zegary TX_CLK i RX_CLK z PHY, 25 MHz przy 100 Mb/s — 16–18 sygnałów. RMII: 2 bity, jeden wspólny zegar referencyjny 50 MHz (z zewnątrz albo z PHY), połączone CRS i DV — mniej pinów, ale wspólny zegar wymaga uwagi przy rozmieszczeniu. RGMII: 4 bity na obu zboczach zegara 125 MHz dla 1 Gb/s (2,5/25 MHz dla 10/100), zegar źródłowo-synchroniczny z przesunięciem 1,5–2 ns (w PHY, w FPGA albo na płytce).
</details>

### [25.04 — Ramki Ethernet, ARP, IP i UDP w sprzęcie](../modules/25-audio-i-ethernet/25.04-ramki-ethernet-arp-ip-i-udp-w-sprzecie.md)

1. **Jak liczy się sumę kontrolną nagłówka IPv4 i dlaczego łatwo ją sprawdzić?**

<details>
<summary>Odpowiedź</summary>

Nagłówek dzieli się na słowa 16-bitowe, pole sumy przyjmuje się jako 0, słowa sumuje w arytmetyce z przeniesieniem cyklicznym (przeniesienie z najstarszego bitu dodaje się do najmłodszego), a wynik neguje. Odbiornik sumuje wszystkie słowa łącznie z polem sumy — dla poprawnego nagłówka wychodzi 0xFFFF (negacja daje 0). Właściwości z RFC 1071: kolejność słów nie ma znaczenia, można liczyć przyrostowo i aktualizować przy zmianie jednego pola (np. TTL w routerze).
</details>

2. **Po co ARP i co się stanie, jeśli FPGA na niego nie odpowiada?**

<details>
<summary>Odpowiedź</summary>

ARP tłumaczy adres IP na adres MAC w sieci lokalnej: nadawca rozgłasza zapytanie „kto ma adres X”, właściciel odpowiada swoim MAC. Bez odpowiedzi komputer nie wyśle żadnego pakietu IP do płytki (aplikacja dostanie błąd albo pakiety utkną w kolejce). Dane w drugą stronę mogą dotrzeć, jeśli FPGA zna MAC komputera albo wysyła na adres rozgłoszeniowy; alternatywą jest statyczny wpis w tablicy ARP komputera.
</details>

3. **Dlaczego strumienie danych z FPGA zwykle idą przez UDP, a nie TCP?**

<details>
<summary>Odpowiedź</summary>

UDP to stały nagłówek i jedna suma (opcjonalna w IPv4) — automat bez stanu połączenia, przepływność ograniczona tylko łączem, minimalne opóźnienie. TCP wymaga nawiązania połączenia, numeracji bajtów, potwierdzeń, retransmisji z buforem niepotwierdzonych danych, okien i kontroli przeciążenia — w logice to duży projekt albo procesor ze stosem. Ceną UDP jest brak gwarancji dostarczenia: aplikacja numeruje pakiety i wykrywa straty, a w sieci punkt–punkt (płytka podłączona wprost do komputera) straty są rzadkie i zwykle wynikają z przepełnienia bufora po stronie odbiorcy.
</details>

### [25.05 — Strumień UDP z FPGA do komputera](../modules/25-audio-i-ethernet/25.05-strumien-udp-z-fpga-do-komputera.md)

1. **Ile danych na sekundę można maksymalnie przesłać przez UDP po Ethernecie 100 Mb/s?**

<details>
<summary>Odpowiedź</summary>

Przy największym datagramie bez fragmentacji (1472 B danych) na kablu przypada 1472 + 66 = 1538 B (preambuła 8, nagłówki 14 + 20 + 8, FCS 4, przerwa 12), więc 100 · 1472 / 1538 ≈ 95,7 Mb/s, czyli ok. 11,96 MB/s. Przy mniejszych datagramach narzut rośnie (1024 B — 93,9 Mb/s, 64 B — ok. 49 Mb/s). Do tego dochodzi zdolność odbiorcy do przyjęcia tylu pakietów na sekundę (8 tys. pakietów/s przy 1472 B).
</details>

2. **Strumień z FPGA gubi co setny pakiet. Jak ustalisz, gdzie?**

<details>
<summary>Odpowiedź</summary>

Numery pakietów w danych pokazują, które zginęły. Potem porównuję liczniki: na płytce (wysłane), w karcie sieciowej (odebrane, błędy CRC — `ethtool -S`/statystyki interfejsu), w Wiresharku/tcpdump (dotarły do systemu) i w aplikacji. Jeśli Wireshark widzi wszystkie pakiety, a aplikacja nie — przepełnia się bufor gniazda (większy `SO_RCVBUF`, szybszy odbiór). Błędy CRC w karcie — problem po stronie MAC/PHY (FCS, czasy MII). Brak pakietów w karcie bez błędów — płytka ich nie wysłała (np. niedobór danych w FIFO, arbiter).
</details>

3. **Jak doprowadzić dane z przetwornika ADC (inny zegar) do nadajnika UDP?**

<details>
<summary>Odpowiedź</summary>

Przez FIFO dwuzegarowe: zapis w domenie ADC, odczyt w domenie TX_CLK. Nadajnik startuje datagram dopiero, gdy w FIFO jest cały datagram (licznik zapełnienia ≥ N), bo MII nie może czekać w środku ramki. Rozmiar FIFO: co najmniej dwa datagramy plus zapas na czas nadawania odpowiedzi ARP i przerw; przepływność ADC musi być mniejsza niż przepływność danych łącza (ok. 94 Mb/s), inaczej FIFO się przepełni — wtedy licznik przepełnień i numer pakietu w danych pozwalają to wykryć.
</details>

## 26 — Cyfrowe przetwarzanie sygnałów w FPGA

### [26.01 — Filtry FIR: struktury bezpośrednia, transponowana, symetryczna i systoliczna](../modules/26-dsp-w-fpga/26.01-filtry-fir-struktury-bezposrednia-transponowana.md)

1. **Dlaczego filtr FIR w postaci transponowanej osiąga wyższy zegar niż bezpośredni?**

<details>
<summary>Odpowiedź</summary>

W postaci bezpośredniej wynik to suma N iloczynów obliczana kombinacyjnie po rejestrach linii opóźniającej — ścieżka zawiera mnożenie i łańcuch (albo drzewo) N−1 dodawań. W transponowanej próbka jest mnożona przez wszystkie współczynniki jednocześnie, a między kolejnymi sumatorami są rejestry sum częściowych: ścieżka to jedno mnożenie i jedno dodawanie, niezależnie od N. Ceną jest duże rozgałęzienie wejścia (próbka zasila N mnożarek) — przy długich filtrach powiela się rejestr wejściowy albo stosuje strukturę systoliczną, w której dane i sumy płyną łańcuchem.
</details>

2. **Filtr 64-współczynnikowy z liniową fazą, 10 MSPS, zegar 200 MHz. Ile mnożarek?**

<details>
<summary>Odpowiedź</summary>

Symetria pozwala liczyć 32 mnożenia na próbkę (sumator wstępny dodaje pary próbek). Na próbkę przypada 200/10 = 20 taktów, więc potrzeba ⌈32/20⌉ = 2 mnożarek pracujących w trybie MAC (każda liczy 16 iloczynów w 16 taktach i akumuluje), plus sumator łączący dwa akumulatory. Bez symetrii — ⌈64/20⌉ = 4. W pełni równoległa transponowana wersja (64 mnożarki) przyjmowałaby próbkę w każdym takcie, czyli 200 MSPS — dziesięć razy więcej, niż trzeba.
</details>

3. **Dlaczego filtr z symetrycznymi współczynnikami ma liniową fazę i dlaczego to ważne?**

<details>
<summary>Odpowiedź</summary>

Odpowiedź częstotliwościowa symetrycznego filtru o długości N daje się zapisać jako e^(−jω(N−1)/2) razy funkcja rzeczywista — faza jest liniową funkcją częstotliwości, czyli wszystkie składowe są opóźnione o tyle samo, (N−1)/2 próbek (opóźnienie grupowe stałe). Kształt impulsu w paśmie przepustowym się nie zmienia — ważne w transmisji danych (brak zniekształceń międzysymbolowych od fazy), w obrazie i w pomiarach. Filtry IIR nie mogą mieć dokładnie liniowej fazy; przy okazji symetria pozwala o połowę zmniejszyć liczbę mnożarek.
</details>

### [26.02 — Filtry IIR i stabilność w arytmetyce stałoprzecinkowej](../modules/26-dsp-w-fpga/26.02-filtry-iir-i-stabilnosc-w-arytmetyce.md)

1. **Co to jest cykl graniczny w filtrze IIR i jak go uniknąć?**

<details>
<summary>Odpowiedź</summary>

To okresowa oscylacja (albo stała wartość różna od zera) na wyjściu filtru IIR przy zerowym wejściu, wywołana kwantyzacją w pętli sprzężenia zwrotnego: nieliniowe zaokrąglanie przy małych amplitudach „kompensuje” tłumienie biegunów, więc sygnał nie gaśnie. Amplituda rośnie, gdy bieguny są blisko okręgu jednostkowego (rzędu ½/(1 − r) LSB). Środki: obcięcie w stronę zera (moduł malejący) w pętli, więcej bitów ułamkowych w pętli (cykl spada poniżej LSB wyjścia), kształtowanie szumu albo dithering. Cykle od przepełnień usuwa nasycenie zamiast zawinięcia.
</details>

2. **Dlaczego pętli filtru IIR nie można po prostu spotokować i co się robi zamiast tego?**

<details>
<summary>Odpowiedź</summary>

Wyjście w[n] zależy od w[n−1] — wynik musi wrócić do pętli przed następną próbką. Dodatkowy rejestr w pętli zmienia równanie różnicowe (w[n] zależałoby od w[n−2]), więc filtr staje się innym filtrem. Rozwiązania: przeplot K niezależnych kanałów (każdy kanał ma swoją próbkę co K taktów, więc K rejestrów w pętli jest poprawne), przekształcenie look-ahead (rozwinięcie rekursji tak, by zależność była od w[n−K], kosztem dodatkowych zer i biegunów, które trzeba zredukować), albo zmniejszenie fs względem zegara i wieloetapowe liczenie jedną mnożarką.
</details>

3. **Dlaczego w stałym przecinku wybiera się często postać transponowaną II albo bezpośrednią I, a nie bezpośrednią II?**

<details>
<summary>Odpowiedź</summary>

W DF-II sygnał wewnętrzny w przechodzi najpierw przez bieguny (część rekursywną), a dopiero potem przez zera — przy biegunach blisko okręgu jego amplituda może być wielokrotnie większa od wejścia i wyjścia, więc stan łatwo się przepełnia albo wymaga skalowania. DF-I ma jeden szeroki akumulator i kwantyzację raz na próbkę, bez stanów pośrednich o dużej dynamice (kosztem 4 rejestrów). DF-II-T ma 2 rejestry, a stany s1, s2 trzymane w pełnej precyzji nie są kwantowane — jedyna kwantyzacja to wyjście; wyjście jest jeden sumator od rejestru, co skraca ścieżkę.
</details>

### [26.03 — Generatory NCO i DDS](../modules/26-dsp-w-fpga/26.03-generatory-nco-i-dds.md)

1. **Akumulator fazy 32-bitowy, zegar 100 MHz. Jaka jest rozdzielczość częstotliwości i jakie słowo ustawia 10 MHz?**

<details>
<summary>Odpowiedź</summary>

Rozdzielczość = 100 MHz / 2³² ≈ 0,0233 Hz. ftw = 10 MHz · 2³² / 100 MHz = 0,1 · 2³² = 429 496 729,6 → 429 496 730 (0x1999999A); rzeczywista częstotliwość różni się od 10 MHz o ok. 0,009 Hz. Przy tak dobranym słowie faza wraca do zera dopiero po bardzo długim czasie, więc widmo prążków od obcięcia fazy jest gęste — ich poziom określa liczba bitów fazy w tablicy, nie dokładność ftw.
</details>

2. **Skąd w widmie DDS biorą się prążki zakłóceń i jak je zmniejszyć?**

<details>
<summary>Odpowiedź</summary>

Z obcięcia fazy przed tablicą: odrzucone bity tworzą błąd fazy, który jest okresowy (powtarza się z okresem zależnym od ftw), więc modulacja fazy daje dyskretne prążki, a nie szum; ich poziom to ok. −6,02 dB na każdy bit fazy użyty w tablicy. Do tego kwantyzacja amplitudy (słabsza przy 16 bitach) i nieliniowości przetwornika C/A. Środki: więcej bitów fazy (większa tablica, kompresja ćwiartkowa), interpolacja lub korekcja Taylora, dithering fazy (zamienia prążki w szum o podobnej mocy, ale rozłożony), CORDIC z dużą liczbą iteracji.
</details>

3. **Jak zbudować przetwornik C/A z jednego pinu FPGA i od czego zależy jego jakość?**

<details>
<summary>Odpowiedź</summary>

Modulator sigma-delta: akumulator, do którego co takt dodaje się próbkę (w kodzie z przesunięciem), a przeniesienie jest bitem wyjściowym — średnia gęstość jedynek jest proporcjonalna do próbki, a błąd kwantyzacji przesunięty do wysokich częstotliwości. Pin z filtrem RC (albo filtrem wyższego rzędu) odtwarza sygnał. Jakość zależy od współczynnika nadpróbkowania (zegar / dwukrotne pasmo), rzędu modulatora (1. rząd ma tony jałowe i słabe kształtowanie), filtru analogowego i warunków analogowych pinu: szumu i stabilności zasilania banku I/O, niesymetrii czasów narastania i opadania oraz jittera zegara. Wyższą jakość daje modulator 2. rzędu i bufor z czystym zasilaniem odniesienia.
</details>

### [26.04 — Decymacja i interpolacja: CIC i filtry wielofazowe](../modules/26-dsp-w-fpga/26.04-decymacja-i-interpolacja-cic-i-filtry.md)

1. **Dlaczego filtr CIC nie potrzebuje mnożarek i dlaczego przepełnienia integratorów mu nie szkodzą?**

<details>
<summary>Odpowiedź</summary>

CIC to kaskada sum ruchomych o długości RM, a sumę ruchomą da się policzyć rekurencyjnie: integrator (dodaj nową próbkę) i grzebień (odejmij próbkę sprzed RM kroków); wszystkie współczynniki są równe 1, więc zostają same sumatory. Integratory są niestabilne (rosną bez ograniczeń przy składowej stałej), ale arytmetyka uzupełnień do dwóch jest arytmetyką modulo 2ᴮ — jeśli B wystarcza na pomieszczenie poprawnego wyniku całego filtru (B_we + N·log₂(RM)), to różnice liczone w grzebieniach wychodzą poprawne mimo zawinięć po drodze. Warunek: zawinięcie wszędzie, żadnego nasycenia.
</details>

2. **CIC: N = 5, R = 64, M = 1, wejście 14-bitowe. Ile bitów mają rejestry i co trzeba dodać za filtrem?**

<details>
<summary>Odpowiedź</summary>

Wzrost słowa N·log₂(RM) = 5·6 = 30 bitów, więc rejestry mają 14 + 30 = 44 bity (przycinanie Hogenauera pozwala zmniejszyć młodsze bity w dalszych stopniach). Wzmocnienie 64⁵ = 2³⁰ kompensuje się przesunięciem o 30. Charakterystyka sinc⁵ mocno opada w paśmie przepustowym, więc za CIC stawia się filtr kompensujący (CFIR) o wzroście wzmocnienia odwrotnym do opadania, zwykle z decymacją przez 2, a potem FIR kształtujący ostateczne pasmo.
</details>

3. **Ile oszczędza struktura wielofazowa przy decymacji przez 8 filtrem 96-współczynnikowym?**

<details>
<summary>Odpowiedź</summary>

Bez niej filtr liczy 96 mnożeń na każdą próbkę wejściową, a 7 z 8 wyników jest wyrzucanych. Wielofazowo liczy się tylko zachowywane wyniki: 96 mnożeń na wynik, czyli 12 na próbkę wejściową — 8 razy mniej (M razy). Sprzętowo: 8 podfiltrów po 12 współczynników pracujących z częstotliwością wyjściową, albo jedna mnożarka z 96 taktami na wynik, jeśli zegar jest co najmniej 12 razy szybszy od próbek wejściowych. Symetria współczynników daje kolejne 2×.
</details>

### [26.05 — FFT w sprzęcie](../modules/26-dsp-w-fpga/26.05-fft-w-sprzecie.md)

1. **Ile mnożeń rzeczywistych wymaga FFT radix-2 dla N = 1024 w porównaniu z DFT?**

<details>
<summary>Odpowiedź</summary>

FFT: log₂1024 = 10 etapów po 512 motyli = 5120 motyli, każdy z jednym mnożeniem zespolonym = 4 mnożenia rzeczywiste, razem ok. 20 480 (mniej, jeśli pominąć mnożenia przez W⁰ = 1 i W^(N/4) = −j, które są trywialne — radix-4 jeszcze bardziej to wykorzystuje). DFT: 1024² ≈ 1,05 mln mnożeń zespolonych, czyli ok. 4,2 mln rzeczywistych — ponad 200 razy więcej.
</details>

2. **Masz strumień 100 MSPS z ADC i zegar 200 MHz. Jaką architekturę FFT 1024 wybierzesz?**

<details>
<summary>Odpowiedź</summary>

Potrzeba przetwarzać 100 M próbek/s bez przerw. Rdzeń iteracyjny z jednym motylem przy 200 MHz wykona ramkę w 5120 taktów, czyli ok. 25,6 µs, a ramka 1024 próbek napływa w 10,24 µs — za wolno. Rozwiązanie: architektura potokowa (np. R2²SDF) przyjmująca próbkę co takt — pracuje przy 200 MHz z 2× zapasem albo przy 100 MHz w tej samej domenie co ADC; ok. log₂N motyli (z mnożeniami zespolonymi tylko w części etapów dla radix-2²) i pamięci opóźniające razem ok. N słów. Alternatywa: kilka rdzeni iteracyjnych z buforami ping-pong, ale potok jest prostszy i tańszy.
</details>

3. **Dlaczego w FFT z podziałem w czasie wejście jest w kolejności z odwróconymi bitami?**

<details>
<summary>Odpowiedź</summary>

Bo algorytm rekurencyjnie dzieli ciąg na próbki parzyste i nieparzyste: w pierwszym podziale decyduje najmłodszy bit indeksu, w drugim kolejny itd. Po log₂N podziałach próbka x[n] ląduje na pozycji, której indeks to n zapisane w odwrotnej kolejności bitów. Liczenie w miejscu (wyniki motyla zapisywane tam, skąd przeczytano argumenty) wymaga więc, żeby dane na początku były w tej kolejności — wtedy wynik wychodzi w kolejności naturalnej. W sprzęcie to darmowe: przestawione przewody adresu.
</details>

### [26.06 — Przetwarzanie I/Q i radio programowalne](../modules/26-dsp-w-fpga/26.06-przetwarzanie-i-q-i-radio-programowalne.md)

1. **Dlaczego w odbiorniku potrzebne są dwie gałęzie I i Q, a nie wystarczy jedna?**

<details>
<summary>Odpowiedź</summary>

Jedna gałąź mnoży sygnał przez cos(fc) i daje sygnał rzeczywisty, w którym składowe fc + Δ i fc − Δ trafiają w to samo miejsce |Δ| — nie da się ich rozdzielić, więc kanał nad i pod nośną nakłada się na siebie, a faza sygnału względem nośnej jest niejednoznaczna. Para I + jQ to sygnał zespolony z niesymetrycznym widmem: +Δ i −Δ są rozróżnialne (różnią się kierunkiem obrotu wskazówki), da się odczytać amplitudę i fazę (√(I² + Q²), atan2(Q, I)), a pasmo zespolone o szerokości B wymaga tylko B próbek zespolonych na sekundę.
</details>

2. **Na wejściu ADC jest sygnał na 70 MHz o paśmie 5 MHz, ADC pracuje przy 100 MSPS. Jak to odebrać w FPGA?**

<details>
<summary>Odpowiedź</summary>

70 MHz leży w drugiej strefie Nyquista (50–100 MHz), więc po próbkowaniu pojawia się jako alias przy 100 − 70 = 30 MHz (z odwróconym widmem). DDC z NCO ustawionym na 30 MHz przesuwa go do zera (odwrócenie widma kompensuje się znakiem Q albo NCO na −30 MHz), potem decymacja: np. CIC ↓5 → CFIR ↓2 → FIR ↓2 daje 5 MSPS zespolonych, wystarczające dla pasma 5 MHz z zapasem na zbocza filtru. Przed ADC potrzebny jest analogowy filtr pasmowy wokół 70 MHz, żeby szum i sygnały z innych stref nie nałożyły się na kanał, a ADC musi mieć pasmo wejściowe obejmujące 70 MHz.
</details>

3. **Co to jest niezrównoważenie I/Q i jak się objawia?**

<details>
<summary>Odpowiedź</summary>

W analogowym mieszaczu kwadraturowym gałęzie I i Q mają nieco różne wzmocnienia i przesunięcie fazy różne od dokładnie 90°. Sygnał zespolony zawiera wtedy, oprócz właściwej składowej przy +Δ, jej słabszą kopię lustrzaną przy −Δ (obraz); tłumienie obrazu wynosi typowo 25–40 dB, co dla sygnałów OFDM z wieloma podnośnymi i silnych sąsiednich kanałów jest za mało. Koryguje się to cyfrowo: estymacja błędu wzmocnienia i fazy (np. z korelacji I i Q w czasie) i macierz 2 × 2 na I/Q, plus usuwanie składowej stałej, często w FPGA w czasie rzeczywistym.
</details>

### [26.07 — Od modelu w Pythonie do RTL — weryfikacja bit w bit](../modules/26-dsp-w-fpga/26.07-od-modelu-w-pythonie-do-rtl-weryfikacja-bit-w.md)

1. **Dlaczego nie porównuje się wyjścia filtru IIR w RTL z modelem zmiennoprzecinkowym z tolerancją?**

<details>
<summary>Odpowiedź</summary>

Bo w pętli sprzężenia zwrotnego różnica kwantyzacji nie jest ograniczona do ±1 LSB: każda różnica wraca do pętli i może się kumulować, a przy zerowym wejściu model zmiennoprzecinkowy gaśnie do zera, podczas gdy poprawny RTL ma cykl graniczny o amplitudzie kilkudziesięciu LSB. Tolerancji nie da się dobrać tak, żeby przepuszczała poprawny RTL i odrzucała błędny (np. z obcięciem zamiast zaokrąglenia). Model całkowitoliczbowy z tą samą kwantyzacją daje porównanie dokładne: każda różnica to błąd, a zachowanie zmiennoprzecinkowe ocenia się osobno miarami jakości.
</details>

2. **Jakie różnice między Pythonem a Verilogiem najczęściej psują model bit w bit?**

<details>
<summary>Odpowiedź</summary>

Zaokrąglanie: `round()` w Pythonie zaokrągla połówki do parzystej, `int()` obcina w stronę zera, a typowy RTL dodaje połowę i przesuwa (połówki w górę) albo przesuwa bez dodawania (floor). Szerokość: liczby Pythona nie przepełniają się, rejestry RTL zawijają — trzeba jawnie zawijać w modelu. Znak: w Verilogu wynik wyrażenia jest bez znaku, jeśli choć jeden operand jest bez znaku (wycinek wektora, konkatenacja), więc mnożenie i `>>>` dają inne wyniki niż w Pythonie. Do tego kolejność operacji (zaokrąglenie każdego iloczynu vs sumy) i faza decymacji (który wynik jest pierwszy).
</details>

3. **Jak zorganizować repozytorium, żeby współczynniki filtru nie rozjechały się między modelem, VHDL i Verilogiem?**

<details>
<summary>Odpowiedź</summary>

Jedno źródło: skrypt modelu generuje wszystkie artefakty — pliki współczynników, moduły ROM albo pakiety stałych w każdym języku, wektory testowe — z nagłówkiem „wygenerowane, nie edytować”. RTL czyta współczynniki z portu, parametru lub wygenerowanego pakietu, nigdy nie wpisuje ich ręcznie. CI uruchamia generator w trybie sprawdzania (generacja do katalogu tymczasowego i porównanie z repozytorium) i wszystkie testbenche — każda niezgodność, także ręczna poprawka w wygenerowanym pliku, zatrzymuje scalanie.
</details>

## 27 — Procesory w FPGA i systemy SoC

### [27.01 — Procesor w FPGA: miękki czy twardy](../modules/27-procesory-i-soc/27.01-procesor-w-fpga-miekki-czy-twardy.md)

1. **Kiedy wybierzesz procesor miękki, a kiedy SoC z procesorem twardym?**

<details>
<summary>Odpowiedź</summary>

Miękki — gdy procesor obsługuje sterowanie i konfigurację o małej przepustowości, układ nie ma wersji SoC albo ma być tani, potrzebny jest determinizm co do taktu, kilka małych niezależnych procesorów albo własne instrukcje; koszt to zasoby logiki i niski zegar. Twardy — gdy potrzebny jest Linux, sieć, systemy plików, duża moc CPU i gotowe kontrolery (DDR, USB, Ethernet, PCIe) po stronie procesora; FPGA robi wtedy akcelerację i interfejsy. Twardy procesor oznacza droższy układ i złożony przepływ uruchamiania (bootloader, drzewo urządzeń, sterowniki), miękki — samodzielne utrzymanie konfiguracji rdzenia i ograniczoną wydajność.
</details>

2. **Procesor miękki osiąga 100 MHz, a algorytm w C zajmuje 2000 instrukcji na próbkę. Czy obsłuży strumień 1 MSPS?**

<details>
<summary>Odpowiedź</summary>

Nie: przy CPI ok. 1,2–1,5 (prosty potok z karami skoków i dostępów do pamięci) 2000 instrukcji to ok. 2400–3000 taktów, czyli 24–30 µs na próbkę — maksymalnie ok. 33–40 tys. próbek/s, 25–30 razy za mało. Trzeba przenieść przetwarzanie próbek do logiki (potok, filtr, akcelerator), procesorowi zostawić konfigurację i wyniki zbiorcze; ewentualnie własne instrukcje albo kilka procesorów, jeśli algorytm się dzieli — ale zwykle logika jest tańsza.
</details>

3. **Co daje otwarta architektura RISC-V w projektach FPGA?**

<details>
<summary>Odpowiedź</summary>

Jedną specyfikację zestawu instrukcji z wieloma implementacjami: rdzenie producentów (Nios V, MicroBlaze V, PolarFire SoC) i open source (VexRiscv, NEORV32, PicoRV32, Ibex) używają tego samego kompilatora (GCC, LLVM), debuggera (OpenOCD, GDB) i bibliotek. Rdzeń open source można przenieść między rodzinami i producentami, zweryfikować i zmodyfikować (np. dodać własne instrukcje w przestrzeni kodów custom), a modułowe rozszerzenia (M, C, A, F, Zicsr) pozwalają dobrać koszt do potrzeb. Brak opłat licencyjnych za architekturę; ceną jest samodzielna odpowiedzialność za weryfikację i wsparcie przy rdzeniach open source.
</details>

### [27.02 — Nios V (RISC-V) w Platform Designer na DECA](../modules/27-procesory-i-soc/27.02-nios-v-risc-v-w-platform-designer-na-deca.md)

1. **Jak program w C „wie”, pod jakim adresem jest peryferium w systemie Platform Designer?**

<details>
<summary>Odpowiedź</summary>

Platform Designer zapisuje opis wygenerowanego systemu w pliku `.sopcinfo`: instancje, adresy bazowe, numery przerwań, parametry. Generator BSP (`niosv-bsp`) czyta ten plik i tworzy `system.h` z makrami w rodzaju `PWM_BASE`, `PWM_IRQ`, `LED_BASE`, a także skrypt konsolidatora z regionami pamięci i listę sterowników dla znanych komponentów. Program używa tych makr; po każdej zmianie systemu (nowy adres, nowe peryferium) BSP trzeba wygenerować ponownie i przebudować aplikację, inaczej adresy w programie są nieaktualne.
</details>

2. **Do czego służy moduł debugowania w Nios V i jak wpływa na projekt?**

<details>
<summary>Odpowiedź</summary>

Moduł debugowania (zgodny ze specyfikacją debugowania RISC-V) pozwala przez JTAG zatrzymać rdzeń, czytać i zapisywać rejestry i pamięć, ustawiać pułapki i krokować — tak działa `niosv-download` (ładowanie `.elf` i start) oraz debuger w RiscFree/GDB. W systemie to dodatkowy agent `dm_agent`, który musi być osiągalny z obu portów zarządcy, i dodatkowa logika JTAG (zegar `altera_reserved_tck` w ograniczeniach). W produkcie końcowym można go wyłączyć dla oszczędności zasobów i bezpieczeństwa, ale wtedy program musi startować z zainicjowanej pamięci albo z Flash.
</details>

3. **Peryferium zgłasza przerwanie poziomem. Co musi zrobić procedura obsługi i dlaczego?**

<details>
<summary>Odpowiedź</summary>

Musi usunąć przyczynę przerwania w peryferium — zwykle zapisać 1 do bitu flagi w rejestrze statusu (W1C) albo odczytać dane, które kasują flagę — zanim wróci. Przerwanie poziomem jest aktywne tak długo, jak warunek trwa; po powrocie z procedury kontroler przerwań od razu wywołałby ją znowu i program główny nigdy by nie ruszył. Kasowanie powinno być na początku procedury (zdarzenie, które przyjdzie w trakcie obsługi, ustawi flagę ponownie i nie zginie), a zmienne współdzielone z programem głównym muszą być `volatile`.
</details>

### [27.03 — Własny peryferial z rejestrami i sterownik w C](../modules/27-procesory-i-soc/27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md)

1. **Dlaczego flagi zdarzeń kasuje się zapisem jedynki (W1C), a nie zwykłym zapisem albo odczytem?**

<details>
<summary>Odpowiedź</summary>

Rejestr statusu zwykle ma kilka flag, które sprzęt ustawia niezależnie. Przy zwykłym zapisie program musiałby odczytać rejestr, wyzerować bit i zapisać wynik — między odczytem a zapisem sprzęt może ustawić inną flagę, którą zapis nadpisze zerem (utrata zdarzenia). W1C kasuje tylko bity, w których zapisano 1; reszta jest nietknięta, a operacja jest atomowa z punktu widzenia magistrali. Kasowanie odczytem jest gorsze, bo każdy odczyt (debugger, podgląd, inny wątek) niszczy informację. W RTL dodatkowo ustawienie wygrywa z kasowaniem w tym samym takcie, żeby nowe zdarzenie nie zginęło.
</details>

2. **Co robi `volatile` w sterowniku i czego nie robi?**

<details>
<summary>Odpowiedź</summary>

Mówi kompilatorowi, że wartość może zmienić się poza programem i że każdy dostęp ma skutki — więc każdy odczyt i zapis w kodzie musi zostać wykonany, w tej liczbie i kolejności względem innych dostępów `volatile`. Bez niego pętla odpytująca flagę po optymalizacji czyta rejestr raz, a zapisy konfiguracyjne mogą zostać połączone albo usunięte. `volatile` nie gwarantuje kolejności względem zwykłych dostępów do pamięci, nie jest barierą dla sprzętu (bufory zapisu, zmiana kolejności w procesorze, pamięć podręczna) i nie daje atomowości odczytu–modyfikacji–zapisu — do tego służą bariery (`fence`), dostęp do regionu niebuforowanego i wyłączanie przerwań albo blokady.
</details>

3. **Jak zaprojektować zmianę okresu PWM w trakcie pracy, żeby nie było zakłóceń?**

<details>
<summary>Odpowiedź</summary>

Rejestry cienia: zapis z magistrali trafia do rejestru „zapisanego”, a licznik używa kopii, która jest aktualizowana tylko na granicy okresu (gdy licznik wraca do zera); przy wyłączonym PWM — od razu. Okres i wypełnienie przepisuje się razem, więc nie powstanie kombinacja nowego okresu ze starym wypełnieniem. Opcjonalnie flaga „zmiana przyjęta” albo przerwanie końca okresu, żeby program wiedział, kiedy może zapisać kolejną wartość. Bez tego zmiana w środku okresu daje skrócony impuls albo okres dłuższy niż oba ustawienia (licznik przekracza nowy, mniejszy okres i liczy do przepełnienia).
</details>

### [27.04 — Otwarte rdzenie RISC-V: PicoRV32, VexRiscv, NEORV32 i LiteX](../modules/27-procesory-i-soc/27.04-otwarte-rdzenie-risc-v-picorv32-vexriscv.md)

1. **Jakiego rdzenia RISC-V użyjesz w małym FPGA do sterowania i jak go sprawdzisz?**

<details>
<summary>Odpowiedź</summary>

Do sterowania o małej wydajności w tanim układzie: PicoRV32 (mały, prosty interfejs, wysoki zegar) albo NEORV32 (gotowe peryferia, bootloader, dokumentacja); przy skrajnym niedoborze logiki SERV. Konfiguracja minimalna: RV32I (+ Zicsr, jeśli potrzebne przerwania), M tylko gdy program dużo mnoży. Sprawdzenie: testy architektoniczne RISC-V (riscv-arch-test przez RISCOF) dla wybranej konfiguracji, program aplikacyjny w symulacji z porównaniem śladu do ISS, test na płytce z konsolą; przy zmianach w rdzeniu — riscv-formal przez RVFI.
</details>

2. **Czym różni się interfejs pamięci PicoRV32 od magistrali w prostym potokowym rdzeniu z pamięcią blokową?**

<details>
<summary>Odpowiedź</summary>

PicoRV32 używa uzgadniania: wystawia `mem_valid` z adresem i czeka, aż pamięć odpowie `mem_ready` — pamięć może odpowiedzieć po dowolnej liczbie taktów (wolna pamięć zewnętrzna, peryferium z oczekiwaniem), a rdzeń w tym czasie stoi. Prosty rdzeń potokowy z pamięcią blokową zakłada stałe opóźnienie (adres w takcie t, dane w t+1) i nie ma sygnału gotowości — jest szybszy (dostęp co takt, bez oczekiwania), ale każde wolniejsze urządzenie wymaga dodania wstrzymania potoku (stall od magistrali) albo bufora. W praktyce rdzenie potokowe mają pamięci TCM o stałym opóźnieniu i osobną magistralę z uzgadnianiem dla reszty systemu.
</details>

3. **Co to jest RVFI i do czego służy?**

<details>
<summary>Odpowiedź</summary>

RISC-V Formal Interface — zestaw sygnałów, które rdzeń wystawia przy każdej wycofanej instrukcji: słowo instrukcji, PC przed i po, numery i wartości rejestrów źródłowych i docelowego, adres, maska i dane dostępu do pamięci. Framework riscv-formal łączy go z modelem ISA zapisanym formalnie i solver (SymbiYosys) dowodzi, że dla każdej sekwencji instrukcji o ograniczonej długości rdzeń zachowuje się zgodnie z ISA — znajduje błędy hazardów, przekazywania i rzadkich przypadków brzegowych. Ten sam interfejs ułatwia porównanie śladu z symulatorem ISS w zwykłej symulacji.
</details>

### [27.05 — Układy SoC z twardym procesorem: Zynq, Cyclone V SoC, Agilex](../modules/27-procesory-i-soc/27.05-uklady-soc-z-twardym-procesorem-zynq-cyclone-v.md)

1. **Którymi portami Zynq połączysz akcelerator, który przetwarza bloki danych w DDR i ma rejestry sterujące?**

<details>
<summary>Odpowiedź</summary>

Rejestry sterujące (start, adresy buforów, długość, status) — przez M_AXI_GP0 jako slave AXI4-Lite (procesor jest zarządcą). Dane — akcelerator jako zarządca AXI4 z burstami przez S_AXI_HP (64 bity, kolejki FIFO, bezpośrednio do kontrolera DDR), zwykle przez rdzeń DMA albo własny silnik. Zakończenie — przerwanie przez IRQ_F2P. Jeśli bufory są w pamięci buforowanej procesora, oprogramowanie robi flush/invalidate (albo używa buforów niebuforowanych); przy małych, częstych przesyłach można użyć ACP dla koherencji, kosztem przepustowości.
</details>

2. **Na czym polega problem koherencji przy DMA i jak go rozwiązać?**

<details>
<summary>Odpowiedź</summary>

Procesor trzyma kopie danych w pamięci podręcznej, a DMA w logice czyta i pisze bezpośrednio DDR. Gdy procesor przygotował dane, mogą one jeszcze nie być w DDR (brudne linie w pamięci podręcznej) — DMA przeczyta stare. Gdy DMA zapisało wynik do DDR, procesor może czytać starą kopię z pamięci podręcznej. Rozwiązania: zapis brudnych linii (flush) przed DMA z pamięci i unieważnienie (invalidate) po DMA do pamięci — w Linuksie przez API DMA; bufory niebuforowane; albo port koherentny (ACP, HPC, ACE), przez który dostęp logiki przechodzi przez kontroler koherencji.
</details>

3. **Jak uruchamia się Zynq-7000 i kto konfiguruje logikę?**

<details>
<summary>Odpowiedź</summary>

Po resecie BootROM w PS odczytuje tryb uruchamiania z pinów i ładuje FSBL z QSPI, SD albo NAND do OCM. FSBL inicjalizuje zegary, DDR i MIO, opcjonalnie ładuje bitstream do PL przez PCAP, a potem kolejny etap (U-Boot albo aplikację bare metal). U-Boot ładuje jądro Linuksa i drzewo urządzeń. Logikę może skonfigurować FSBL, U-Boot albo działający Linux (FPGA Manager, także rekonfiguracja częściowa). Procesor jest więc „panem” — PL nie działa, dopóki PS go nie skonfiguruje, inaczej niż w Cyclone V SoC, gdzie FPGA można skonfigurować także niezależnie od HPS.
</details>

### [27.06 — Linux na FPGA i podział sprzęt–oprogramowanie](../modules/27-procesory-i-soc/27.06-linux-na-fpga-i-podzial-sprzetoprogramowanie.md)

1. **Jak aplikacja w Linuksie dostanie się do rejestrów Twojego bloku w FPGA i obsłuży jego przerwanie?**

<details>
<summary>Odpowiedź</summary>

Najpierw opis w drzewie urządzeń (albo nakładce): adres fizyczny i rozmiar rejestrów (`reg`), przerwanie (`interrupts`) i `compatible`. Dla prototypu: `compatible` dopasowany do sterownika UIO (`generic-uio`/`uio_pdrv_genirq`) — aplikacja otwiera `/dev/uioN`, mapuje rejestry przez `mmap`, czeka na przerwanie blokującym `read()`, kasuje flagę w bloku i odblokowuje przerwanie zapisem do `/dev/uioN`. Dla produktu: sterownik jądra (platform driver) z `probe()`, `devm_platform_ioremap_resource`, `request_irq` i interfejsem dla aplikacji (urządzenie znakowe, sysfs albo podsystem jądra: IIO, PWM, sieć, V4L2). `/dev/mem` tylko do szybkiego testu.
</details>

2. **Funkcja zajmuje 40% czasu programu. W FPGA będzie 50× szybsza, ale przesłanie danych zajmuje 5% pierwotnego czasu. Ile zyskasz?**

<details>
<summary>Odpowiedź</summary>

Bez przesyłu: S = 1/(0,6 + 0,4/50) = 1/0,608 ≈ 1,64. Z przesyłem (jeśli nie nakłada się na obliczenia): 1/(0,6 + 0,008 + 0,05) = 1/0,658 ≈ 1,52. Ograniczeniem jest 60% czasu, które zostaje w oprogramowaniu — nawet nieskończenie szybki akcelerator dałby najwyżej 1/0,6 ≈ 1,67. Żeby zyskać więcej, trzeba przenieść także inne części albo przepisać program (np. potokowe nakładanie przesyłu i obliczeń, przetwarzanie strumieniowe zamiast blokowego).
</details>

3. **Co to jest FPGA Manager i nakładka drzewa urządzeń?**

<details>
<summary>Odpowiedź</summary>

FPGA Manager to podsystem jądra Linuksa, który ładuje bitstream do logiki przez sterownik specyficzny dla układu (PCAP w Zynq, menedżer konfiguracji w SoC Altery). FPGA Region i nakładki drzewa urządzeń łączą konfigurację z opisem sprzętu: nakładka wskazuje plik bitstreamu i zawiera węzły urządzeń znajdujących się w nowej logice; jądro wyłącza mosty, ładuje bitstream (cały albo częściowy), włącza mosty i dopiero wtedy tworzy urządzenia i uruchamia ich sterowniki. Dzięki temu logikę można wymieniać w działającym systemie, także częściowo (rekonfiguracja częściowa jednego regionu).
</details>

### [27.07 — Własny procesor RISC-V: od jednocyklowego do potokowego](../modules/27-procesory-i-soc/27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md)

1. **Co to jest hazard load-use i dlaczego przekazywanie go nie usuwa?**

<details>
<summary>Odpowiedź</summary>

Instrukcja odczytu z pamięci (np. `lw t2, 0(t0)`) ma dane dopiero na końcu stopnia MEM (w rdzeniu z pamięcią blokową — w WB), a następna instrukcja, która używa `t2`, potrzebuje go na początku EX — czyli wcześniej, niż dane istnieją. Przekazywanie może podać tylko wartość, która już gdzieś jest; tu trzeba wstrzymać instrukcję zależną o 1 takt (bąbelek w EX, IF i ID stoją), po czym dane przechodzą przez przekazywanie z WB. Kompilator zmniejsza koszt, wstawiając między odczyt a użycie niezależną instrukcję (planowanie instrukcji).
</details>

2. **Ile kosztuje wykonany skok warunkowy w potoku 5-stopniowym i jak to zmniejszyć?**

<details>
<summary>Odpowiedź</summary>

Jeśli skok rozstrzyga się w EX, a potok zakłada „niewykonany”, to po wykonanym skoku dwie instrukcje pobrane z błędnej ścieżki (w IF i ID) trzeba wyrzucić — 2 takty kary; tu 341 wykonanych skoków dało 682 takty z 2742. Zmniejszenie: rozstrzyganie skoków w ID (porównanie i sumator celu wcześniej — 1 takt, ale dłuższa ścieżka ID i więcej przekazywania do ID), predykcja statyczna (skoki wstecz wykonane — pętle), predykcja dynamiczna (liczniki 2-bitowe, BTB z celami skoków), skoki opóźnione (nie w RISC-V) albo instrukcje warunkowe zamiast skoków w kodzie.
</details>

3. **Jak zweryfikujesz własny rdzeń RISC-V?**

<details>
<summary>Odpowiedź</summary>

Wzorcem jest niezależny model zestawu instrukcji (ISS: własny, Spike albo Sail). Program testowy wykonuje się w obu, a porównuje się ślad: wycofane instrukcje (PC, rd, wartość) albo zapisy do pamięci — niezależnie od liczby taktów, więc ten sam test sprawdza rdzeń jednocyklowy i potokowy. Program musi celowo zawierać sekwencje trudne dla potoku (zależności tuż po sobie, load-use, odczyt i zapis tego samego adresu, skoki od świeżo odczytanych danych, x0) i przypadki brzegowe ISA. Do tego testy architektoniczne (riscv-arch-test przez RISCOF), losowe programy (riscv-dv) i weryfikacja formalna przez RVFI (riscv-formal), która znajduje rzadkie błędy hazardów.
</details>

## 28 — Synteza wysokiego poziomu (HLS) i akceleracja

### [28.01 — Czym jest HLS i kiedy się opłaca](../modules/28-hls-i-akceleracja/28.01-czym-jest-hls-i-kiedy-sie-oplaca.md)

1. **Co robi narzędzie HLS z pętlą `for` w C?**

<details>
<summary>Odpowiedź</summary>

Domyślnie pętla staje się sekwencją stanów automatu: iteracje wykonują się jedna po drugiej, każda przez tyle taktów, ile trwa jej ciało, plus takt na sprawdzenie warunku — współdzielone jednostki, mało zasobów, długi czas. Z dyrektywą PIPELINE iteracje nakładają się: nowa zaczyna się co II taktów (interwał inicjacji), a ciało jest potokiem o pewnej głębokości — czas ≈ głębokość + (N − 1)·II. Z UNROLL (pełnym albo o współczynnik) ciało jest powielane — więcej sprzętu, mniej iteracji. Pętla o nieznanej liczbie iteracji też się syntezuje, ale raport nie poda opóźnienia bez LOOP_TRIPCOUNT.
</details>

2. **Czym różni się symulacja C od kosymulacji C/RTL i po co obie?**

<details>
<summary>Odpowiedź</summary>

Symulacja C kompiluje funkcję i testbench zwykłym kompilatorem i uruchamia — trwa sekundy, sprawdza algorytm (i zakresy typów o stałej szerokości), ale nic nie mówi o sprzęcie. Kosymulacja używa tego samego testbencha, ale wywołania funkcji zamienia na pobudzenia wygenerowanego RTL w symulatorze HDL — sprawdza, że synteza zachowała funkcję (np. dyrektywa DEPENDENCE false nie była kłamstwem), że protokół interfejsów działa, i mierzy rzeczywistą liczbę taktów i II. Jest wolna, więc uruchamia się ją na mniejszych zbiorach testowych, a symulację C — na pełnych.
</details>

3. **Kiedy nie użyjesz HLS?**

<details>
<summary>Odpowiedź</summary>

Gdy liczy się dokładne zachowanie co do taktu na interfejsach: kontrolery pamięci, PHY i MAC protokołów, obsługa I/O z ograniczeniami czasowymi, układy wielozegarowe i przejścia między domenami — RTL daje pełną kontrolę i przewidywalność. Gdy układ jest mały i sterujący (automat, licznik, rejestry), bo RTL jest krótszy i czytelniejszy niż kod z dyrektywami. Gdy projekt jest na granicy zasobów lub zegara i potrzebne są ręczne optymalizacje (dopasowanie do bloków DSP, kaskady, floorplanning). Wreszcie, gdy zespół nie ma doświadczenia w czytaniu raportów HLS — bez tego wyniki bywają przypadkowe.
</details>

### [28.02 — Pętle: potokowanie, rozwijanie i interwał inicjacji (II)](../modules/28-hls-i-akceleracja/28.02-petle-potokowanie-rozwijanie-i-interwal.md)

1. **Raport HLS mówi: pętla sumowania float ma II = 5 zamiast 1. Dlaczego i co zrobisz?**

<details>
<summary>Odpowiedź</summary>

Każda iteracja dodaje do akumulatora wynik poprzedniej, a sumator zmiennoprzecinkowy ma opóźnienie kilku taktów (tu 5) — zależność przenoszona przez pętlę daje RecMII = 5/1. Rozwiązania: kilka (≥ 5) akumulatorów częściowych używanych po kolei (`acc[i % 5] += a[i]`) i zsumowanie ich po pętli — odległość zależności 5, RecMII = 1; zmiana na arytmetykę stałoprzecinkową z 1-taktowym sumatorem; obniżenie zegara (krótsze opóźnienie sumatora). Akumulatory częściowe zmieniają kolejność dodawania, więc wynik float może różnić się w ostatnich bitach — trzeba to uwzględnić w testach.
</details>

2. **Rozwinąłeś pętlę o 16, a czas prawie się nie zmienił. Co sprawdzisz?**

<details>
<summary>Odpowiedź</summary>

Porty pamięci: 16 kopii czyta tę samą tablicę, a blok pamięci ma 2 porty — ResMII = 8, więc zysk najwyżej 2×. Trzeba podzielić tablicę (ARRAY_PARTITION cyclic factor=16 albo complete dla wymiaru, po którym idzie rozwinięta pętla) albo przeorganizować dane (szersze słowa, ARRAY_RESHAPE). Druga przyczyna: zależność między kopiami (np. łańcuch sum), którą narzędzie realizuje szeregowo — sprawdzić głębokość i strukturę sumowania. Trzecia: interfejs zewnętrzny (AXI) nie dostarcza 16 elementów na takt — wtedy wąskim gardłem jest pamięć DDR, nie jądro.
</details>

3. **Co to jest II i jak wpływa na przepustowość i zasoby?**

<details>
<summary>Odpowiedź</summary>

Interwał inicjacji — liczba taktów między rozpoczęciem kolejnych iteracji pętli potokowanej (albo kolejnych wywołań funkcji). Przepustowość = f_clk / II wyników na sekundę; opóźnienie jednej iteracji (głębokość) jest osobnym parametrem. Większe II pozwala współdzielić jednostki: przy II = 4 jedna mnożarka obsłuży 4 mnożenia z jednej iteracji, więc zasobów jest mniej — to podstawa kompromisu przepustowość–zasoby (w hls4ml nazywany *reuse factor*). II = 1 to maksymalna przepustowość i najwięcej zasobów.
</details>

### [28.03 — Interfejsy i pamięć w HLS](../modules/28-hls-i-akceleracja/28.03-interfejsy-i-pamiec-w-hls.md)

1. **Jak HLS zrealizuje argument `int *x` i od czego to zależy?**

<details>
<summary>Odpowiedź</summary>

Od dyrektywy INTERFACE i sposobu użycia w kodzie. Domyślnie (zależnie od narzędzia i trybu) wskaźnik do tablicy staje się portem pamięci (`ap_memory` — adres, dane, zapis) albo zarządcą AXI4 (`m_axi`) czytającym pamięć systemu, z adresem bazowym w rejestrze AXI4-Lite. Gdy kod czyta `x` dokładnie raz, sekwencyjnie, może to być strumień (`axis`/FIFO). Wskaźnik do skalaru używany tylko do odczytu staje się wejściem, tylko do zapisu — wyjściem (z sygnałem ważności `ap_vld`), do obu — parą portów. Ważne: dla `m_axi` wydajność zależy od burstów, więc wzorzec dostępu w kodzie decyduje o przepustowości.
</details>

2. **Jaki podział tablicy wybierzesz dla pętli rozwiniętej o 4, która czyta `t[4i]`, `t[4i+1]`, `t[4i+2]`, `t[4i+3]`?**

<details>
<summary>Odpowiedź</summary>

`ARRAY_PARTITION cyclic factor=4` — element o indeksie j trafia do banku j mod 4, więc cztery kolejne elementy są w czterech różnych bankach i można je przeczytać w jednym takcie (każdy bank ma jeszcze drugi port). `block factor=4` byłby zły: dzieli tablicę na cztery ciągłe kawałki, a kolejne elementy leżą w tym samym kawałku. Alternatywa: `ARRAY_RESHAPE cyclic factor=4` — cztery elementy w jednym szerokim słowie jednej pamięci, jeden dostęp czyta wszystkie (mniej bloków pamięci, ta sama przepustowość).
</details>

3. **Co daje dyrektywa DATAFLOW i kiedy nie zadziała?**

<details>
<summary>Odpowiedź</summary>

Zamienia sekwencję funkcji lub pętli w potok zadań: każda działa jako osobny blok sprzętowy jednocześnie z pozostałymi, komunikując się przez FIFO (dostęp sekwencyjny) albo bufory ping-pong (tablice). Opóźnienie całości to suma, ale przepustowość — rytm najwolniejszego etapu, zamiast sumy czasów. Nie zadziała (albo narzędzie wycofa się do wykonania sekwencyjnego), gdy zmienna ma wielu producentów lub konsumentów, gdy etap czyta wynik późniejszego (sprzężenie zwrotne), gdy między etapami jest kod warunkowy omijający etap, albo gdy dane są przekazywane przez zmienne globalne. Trzeba też dobrać głębokość FIFO, żeby etapy o nierównym rytmie się nie zakleszczyły.
</details>

### [28.04 — Narzędzia: Vitis HLS, oneAPI i Bambu](../modules/28-hls-i-akceleracja/28.04-narzedzia-vitis-hls-oneapi-i-bambu.md)

1. **Opisz przepływ pracy w Vitis HLS od kodu do IP.**

<details>
<summary>Odpowiedź</summary>

Funkcja główna w C++ z dyrektywami i testbench zwracający 0 przy sukcesie. Symulacja C (sprawdzenie algorytmu), synteza C (raport: opóźnienie, II pętli z przyczynami naruszeń, oszacowanie zegara, zasoby, interfejsy — iteracje z dyrektywami do osiągnięcia celu), kosymulacja C/RTL (ten sam testbench na wygenerowanym RTL — poprawność funkcji i protokołów, rzeczywiste takty), eksport jako IP do Vivado (albo jądro `.xo`), opcjonalnie z uruchomieniem implementacji dla rzeczywistych zasobów i zegara. Całość w skrypcie Tcl albo pliku konfiguracyjnym, żeby dało się powtórzyć w CI.
</details>

2. **Czym różni się szeregowanie statyczne od dynamicznego w HLS?**

<details>
<summary>Odpowiedź</summary>

Statyczne ustala w czasie kompilacji, w którym takcie wykonuje się każda operacja; sprzęt to automat lub potok bez uzgadniania wewnątrz — mały i szybki, ale musi zakładać najgorszy przypadek: jeśli zależność przez pamięć może wystąpić, II jest zwiększane dla wszystkich iteracji. Dynamiczne (np. Dynamatic) buduje obwód sterowany przepływem danych: operacje komunikują się sygnałami valid/ready, a jednostka zgłoszeń pamięci rozstrzyga konflikty w czasie pracy — czeka tylko wtedy, gdy zależność naprawdę zachodzi. Zyskuje się na nieregularnych pętlach (histogramy, dostęp przez indeksy z danych), traci na zasobach i zegarze przez logikę uzgadniania.
</details>

3. **Raport HLS podaje zegar 300 MHz, a po implementacji jest 180 MHz. Dlaczego i co zrobisz?**

<details>
<summary>Odpowiedź</summary>

Raport HLS szacuje opóźnienia operacji z bibliotek i nie zna rozmieszczenia ani połączeń: duże rozgałęzienia (rejestry zasilające wiele rozwiniętych kopii), długie multipleksery przy współdzieleniu, pamięci rozrzucone po układzie i łańcuchy operacji w jednym takcie wychodzą dopiero po implementacji. Działania: ustawić w HLS krótszy okres (zapas) albo niepewność zegara, żeby narzędzie dzieliło łańcuchy na więcej taktów; ograniczyć rozwinięcia i rozgałęzienia (powielanie rejestrów, mniejsze partycje); obejrzeć ścieżkę krytyczną w raporcie czasowym implementacji i odnaleźć ją w kodzie (nazwy sygnałów, Schedule Viewer); ewentualnie zostawić tę część w RTL.
</details>

### [28.05 — Akceleracja sieci neuronowych: hls4ml i FINN](../modules/28-hls-i-akceleracja/28.05-akceleracja-sieci-neuronowych-hls4ml-i-finn.md)

1. **Jak zamienisz sieć wytrenowaną w float na wnioskowanie int8 w FPGA?**

<details>
<summary>Odpowiedź</summary>

Wyznaczam zakresy wag i aktywacji (na danych kalibracyjnych), dobieram skale (najprościej potęgi dwójki, żeby przeskalowanie było przesunięciem; ogólnie mnożenie przez stałą i przesunięcie), kwantyzuję wagi do int8 z zaokrągleniem i nasyceniem, biasy do int32 w skali iloczynu, wkładam normalizację wsadową w wagi. W sprzęcie: iloczyny int8 sumowane w int32, przeskalowanie z zaokrągleniem, aktywacja i nasycenie do int8 przed następną warstwą; na końcu argmax na logitach. Tworzę model całkowitoliczbowy w Pythonie jako wzorzec bitowy, porównuję dokładność z float na zbiorze testowym, a sprzęt (HLS lub RTL) testuję co do bitu względem modelu całkowitoliczbowego. Przy dużej utracie dokładności — trening z kwantyzacją (QAT).
</details>

2. **Co to jest reuse factor w hls4ml i jak wpływa na projekt?**

<details>
<summary>Odpowiedź</summary>

To liczba mnożeń przypadających na jedną fizyczną mnożarkę w warstwie: R = 1 oznacza pełną równoległość (każda waga ma mnożarkę, nowa próbka co takt, najmniejsze opóźnienie, najwięcej DSP/LUT), R = k — mnożarek k razy mniej, II i opóźnienie rosną proporcjonalnie. Dobiera się go, żeby zmieścić sieć w układzie przy wymaganej przepustowości: np. przy zegarze 200 MHz i 10 M próbek/s można przyjąć R ≈ 20. Wpływa też na czas syntezy (R = 1 dla dużych warstw to bardzo duży kod po rozwinięciu) i na sposób przechowywania wag (rejestry vs pamięci blokowe).
</details>

3. **Kiedy wybrać FINN, hls4ml, a kiedy nakładkę typu DPU?**

<details>
<summary>Odpowiedź</summary>

hls4ml — małe i średnie sieci (MLP, małe CNN) z wymaganiem minimalnego opóźnienia (ns–µs, np. wyzwalacze w fizyce), modele z Keras/PyTorch, różne back-endy HLS. FINN — sieci mocno kwantyzowane (1–4 bity, Brevitas) o dużej przepustowości, gdzie całą sieć da się rozwinąć w potok strumieniowy na układzie AMD. DPU/FPGA AI Suite — duże modele (ResNet, YOLO) i potrzeba podmiany modeli bez ponownej syntezy sprzętu: jeden zoptymalizowany procesor sieci, kompilator modeli, wyższe opóźnienie i zasoby, ale krótki czas wdrożenia. Decydują: rozmiar modelu, wymagane opóźnienie i przepustowość, precyzja, rodzina układu i to, jak często model się zmienia.
</details>

### [28.06 — Alternatywne języki HDL: Chisel, SpinalHDL, Amaranth, Clash](../modules/28-hls-i-akceleracja/28.06-alternatywne-jezyki-hdl-chisel-spinalhdl.md)

1. **Czym Chisel różni się od HLS?**

<details>
<summary>Odpowiedź</summary>

Chisel to język konstrukcji sprzętu: opisuje się rejestry, logikę kombinacyjną i połączenia, a o tym, co dzieje się w którym takcie, decyduje projektant — tak jak w Verilogu. Różnica względem Veriloga polega na tym, że opis tworzy program w Scali: pętle, funkcje, klasy, parametry i typy pozwalają pisać generatory (np. procesor z konfigurowalną liczbą rdzeni i pamięci podręcznych). HLS natomiast przyjmuje algorytm bez informacji o taktach i sam układa operacje w czasie, dobiera jednostki i generuje sterowanie — projektant wpływa na to dyrektywami. Chisel daje pełną kontrolę i przewidywalność, HLS — szybkość pisania algorytmów kosztem kontroli.
</details>

2. **Jakie są wady języków takich jak SpinalHDL czy Amaranth w projekcie przemysłowym?**

<details>
<summary>Odpowiedź</summary>

Wygenerowany Verilog jest słabo czytelny, więc analiza czasowa, debugowanie na płytce i przeglądy kodu z osobami spoza projektu są trudniejsze. Dochodzi zależność od kompilatora i jego wersji (zmiany API, błędy generatora), mniejsza liczba specjalistów na rynku i potrzeba znajomości dwóch światów (język gospodarza i HDL/narzędzia producenta — ograniczenia, IP, CDC). Narzędzia weryfikacji przemysłowej (UVM, formalne, pokrycie) są zbudowane wokół SystemVerilog. Zalety (generatory, biblioteki, typy, testy w Pythonie/Scali) opłacają się przy dużych, parametrycznych projektach i w zespołach, które utrzymują własne biblioteki.
</details>

3. **Jak sprawdzisz, że układ wygenerowany w Amaranth jest równoważny ręcznemu RTL?**

<details>
<summary>Odpowiedź</summary>

Najprościej — tymi samymi wektorami i tym samym wzorcem bitowym: symulacja w Amaranth porównana z modelem, a potem wygenerowany Verilog w symulatorze HDL z testbenchem używanym dla ręcznego RTL (tu `tb_fir_amaranth.v` na wektorach modułu 26 — 2048 próbek bez niezgodności). Mocniej: sprawdzenie równoważności formalnej (np. Yosys `equiv_*` albo SymbiYosys z miterem łączącym oba układy na wspólnych wejściach i porównaniem wyjść) — przy tych samych rejestrach i opóźnieniach dowodzi równoważności dla wszystkich wejść, nie tylko testowych.
</details>

## 29 — Konfiguracja, bezpieczeństwo i niezawodność

### [29.01 — Tryby konfiguracji i pamięci konfiguracyjne](../modules/29-konfiguracja-niezawodnosc/29.01-tryby-konfiguracji-i-pamieci-konfiguracyjne.md)

1. **Co się dzieje z FPGA SRAM od włączenia zasilania do pracy projektu?**

<details>
<summary>Odpowiedź</summary>

Układ czeka na stabilne zasilania (POR), czyści pamięć konfiguracji (pin `nSTATUS`/`INIT_B` niski — host może ten etap przedłużyć), próbkuje piny trybu i ładuje bitstream: nagłówek, ramki konfiguracji z sumą kontrolną każdej ramki — błąd przerywa ładowanie. Potem inicjalizacja: zerowanie rejestrów, zwolnienie globalnych sygnałów zapisu i trójstanu, włączenie wyjść; `DONE` idzie wysoko i projekt działa. Przez cały czas wyjścia są w stanie Z. Ponowna konfiguracja — `nCONFIG`/`PROGRAM_B` w stanie niskim albo rozkaz z logiki.
</details>

2. **Czym MAX 10 różni się w konfiguracji od Cyclone 10 LP i od PolarFire?**

<details>
<summary>Odpowiedź</summary>

Cyclone 10 LP to klasyczny SRAM: bitstream trzeba załadować z zewnętrznej pamięci (AS) albo z hosta (PS/FPP) przy każdym starcie. MAX 10 ma tę samą komórkę SRAM, ale bitstream przechowuje w wewnętrznym flashu (CFM) i ładuje go sam — nie ma zewnętrznej pamięci ani bitstreamu na płytce, a dwa obrazy w CFM pozwalają na zdalną aktualizację z powrotem do obrazu zapasowego. PolarFire trzyma konfigurację w nieulotnych komórkach, które same sterują przełącznikami — nic się nie ładuje (logika działa od razu po zasilaniu), a konfiguracja nie ulega SEU; za to proces technologiczny i rozmiary są inne niż w wiodących układach SRAM.
</details>

3. **Wymaganie: układ ma odpowiedzieć po PCIe w ciągu 100 ms od zasilania, bitstream ma 80 Mb. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Liczę: SPI ×4 przy 100 MHz daje 80·10⁶ / 4·10⁸ = 0,2 s — za długo, a jeszcze dochodzi czas POR. Opcje: kompresja bitstreamu (jeśli logika nie jest pełna, plik maleje znacznie), szersza szyna (SPI ×8 dwiema pamięciami albo BPI ×16), wyższy zegar konfiguracji z zewnętrznego oscylatora, a jeśli to nie wystarcza — konfiguracja dwuetapowa (Tandem w AMD, CvP w Altera): najpierw mały obraz z blokiem PCIe, który zdąży, a reszta logiki ładowana potem, z pamięci albo przez samo łącze PCIe. Do tego sprawdzam, czy układ w ogóle obsługuje taki tryb, i mierzę czas na prototypie.
</details>

### [29.02 — Podwójny obraz i zdalna aktualizacja w MAX 10](../modules/29-konfiguracja-niezawodnosc/29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md)

1. **Jak zaprojektujesz zdalną aktualizację FPGA, która nie zostawi urządzenia martwego?**

<details>
<summary>Odpowiedź</summary>

Dwa obrazy: niezmienny obraz złoty i obszar na aplikację. Nowy obraz zapisuję tylko do obszaru aplikacji, po zapisie liczę CRC (lepiej sprawdzam podpis) z odczytu pamięci, a przełączam dopiero przy zgodności. Po przełączeniu działa licznik nadzorujący konfiguracji: nowa aplikacja musi go zerować z miejsca, które dowodzi, że działa; gdy nie wystartuje (błąd CRC przy ładowaniu) albo zawiśnie, układ wraca do obrazu złotego, który zgłasza przyczynę z rejestrów statusu. Zanik zasilania w dowolnym momencie zapisu kończy się startem z obrazu złotego. W MAX 10 robi to tryb dwóch obrazów i Dual Configuration IP, w AMD MultiBoot z fallbackiem.
</details>

2. **Po co licznik nadzorujący konfiguracji, skoro układ sprawdza CRC bitstreamu przy ładowaniu?**

<details>
<summary>Odpowiedź</summary>

CRC przy ładowaniu wykrywa tylko uszkodzony plik. Obraz może być bitowo poprawny, a mimo to nie działać: błąd w projekcie, inna wersja sprzętu, zła konfiguracja zegarów, oprogramowanie procesora, które się wiesza. Licznik nadzorujący sprawdza zachowanie, nie bity — aplikacja musi go regularnie zerować, a jeśli przestanie, układ wraca do obrazu zapasowego. To jedyna ochrona przed obrazem „poprawnym, ale złym”.
</details>

3. **Dlaczego moduł czeka 600 taktów zamiast od razu wyzwolić rekonfigurację?**

<details>
<summary>Odpowiedź</summary>

Rdzeń Dual Configuration po zapisie rejestru wejściowego przekazuje go do obwodu zdalnej aktualizacji, co trwa do 531 taktów; w tym czasie ignoruje zapisy (poza zerowaniem licznika). Zapis wyzwalający rekonfigurację wysłany za wcześnie zginąłby i układ zostałby w starym obrazie. Producent zaleca odpytywanie bitu `busy`; stałe czekanie z zapasem jest prostsze, nie zależy od opóźnienia odczytu interfejsu i przy jednorazowej operacji nic nie kosztuje — testbench z modelem rdzenia sprawdza, że odstęp jest większy niż 531 i że żaden zapis nie zginął.
</details>

### [29.03 — Szyfrowanie i ochrona bitstreamu](../modules/29-konfiguracja-niezawodnosc/29.03-szyfrowanie-i-ochrona-bitstreamu.md)

1. **Bitstream jest zaszyfrowany AES-256. Czy to wystarczy, żeby nikt nie podmienił projektu?**

<details>
<summary>Odpowiedź</summary>

Nie. Szyfrowanie zapewnia poufność, nie autentyczność: bez uwierzytelnienia (HMAC, AES-GCM, podpis) można manipulować zaszyfrowanymi blokami albo podać układowi inny zaszyfrowany obraz tym samym kluczem — np. starszą wersję z luką. Potrzebne jest uwierzytelnienie sprawdzane przed użyciem danych, blokada cofania wersji i ochrona klucza. Przykład z praktyki: w 7 Series HMAC był sprawdzany po interpretacji danych, co umożliwiło atak Starbleed i odzyskanie całego bitstreamu.
</details>

2. **MAX 10 nie uwierzytelnia bitstreamu. Jak zabezpieczysz w nim zdalną aktualizację?**

<details>
<summary>Odpowiedź</summary>

Uwierzytelnienie przenoszę do obrazu złotego: każdy obraz aktualizacji jest podpisany (np. ECDSA lub RSA) kluczem prywatnym trzymanym u producenta, a obraz złoty — w logice albo na procesorze Nios — sprawdza podpis kluczem publicznym przed zapisem do CFM i jeszcze raz z odczytu przed przełączeniem. Obraz jest dodatkowo szyfrowany AES-128 z opcją przyjmowania tylko zaszyfrowanych plików, JTAG Secure i Verify Protect blokują dostęp z zewnątrz, a numer wersji w podpisanym nagłówku chroni przed cofnięciem. Obraz złoty i klucz publiczny muszą być chronione przed zapisem (w 10M50DD — kontrola dostępu do obszarów flasha).
</details>

3. **Na czym polega atak DPA na szyfrowanie bitstreamu i jak się przed nim bronić?**

<details>
<summary>Odpowiedź</summary>

Atakujący wielokrotnie konfiguruje układ (różnymi bitstreamami lub tym samym) i mierzy chwilowy pobór prądu podczas odszyfrowywania. Pobór zależy od wartości pośrednich AES, więc statystyczna korelacja pomiarów z hipotezami o bajtach klucza pozwala wyznaczyć klucz bajt po bajcie. Obrona: ograniczenie liczby prób (licznik nieudanych konfiguracji kasujący klucz), klucz sesyjny zmieniany w trakcie odszyfrowywania (np. w AES-GCM z rotacją klucza), maskowanie i szum w implementacji, uwierzytelnienie przed odszyfrowaniem, żeby atakujący nie mógł podawać dowolnych danych.
</details>

### [29.04 — Promieniowanie i SEU: TMR, scrubbing i ECC](../modules/29-konfiguracja-niezawodnosc/29.04-promieniowanie-i-seu-tmr-scrubbing-i-ecc.md)

1. **Na czym polega TMR i dlaczego wersja z resynchronizacją jest lepsza?**

<details>
<summary>Odpowiedź</summary>

Trzy kopie logiki, wynik z głosowania 2 z 3 dla każdego bitu — błąd jednej kopii jest maskowany. Bez resynchronizacji kopie z rejestrami (liczniki, automaty) liczą od własnego stanu, więc trafiona kopia zostaje błędna na zawsze, a kolejne trafienie w inną kopię w tym samym bicie daje błędny wynik — ochrona działa tylko do pierwszego błędu. Z resynchronizacją każda kopia ładuje wynik głosowania, więc błędna kopia wraca do zgodności w następnym takcie; system zawodzi dopiero przy dwóch błędach w różnych kopiach w tym samym takcie. W testbenchu tego tematu przy czterech trafieniach wersja z resynchronizacją nie pomyliła się ani razu, wersja bez niej dała 260 błędnych wyników. Trzeba też pilnować, by synteza nie scaliła kopii i by głosowanie samo nie było pojedynczym punktem awarii.
</details>

2. **Pamięć ma ECC SECDED. Po co jeszcze scrubbing?**

<details>
<summary>Odpowiedź</summary>

SECDED poprawia błąd tylko w danych wysłanych na wyjście — słowo w pamięci nadal ma zły bit. Jeśli zanim zostanie nadpisane, w to samo słowo trafi drugi SEU, mamy błąd podwójny: wykryty, ale niepoprawialny, dane są stracone. Słowa rzadko czytane i rzadko zapisywane (tablice konfiguracji, pamięć programu) zbierają błędy najdłużej. Scrubbing okresowo czyta całą pamięć i zapisuje poprawione słowa, więc błędy nie mają czasu się kumulować; okres dobiera się z częstości błędów i rozmiaru pamięci. Trzeba przy tym zadbać, by zapis zwrotny nie nadpisał zapisu użytkownika, który nastąpił w międzyczasie.
</details>

3. **Jak oszacujesz, czy projekt na FPGA SRAM potrzebuje ochrony przed SEU?**

<details>
<summary>Odpowiedź</summary>

Biorę z raportu niezawodności producenta wskaźnik FIT/Mb dla CRAM i pamięci blokowych, z narzędzia — liczbę bitów istotnych mojego projektu (nie całego CRAM), uwzględniam otoczenie (wysokość, szerokość geograficzna, obudowa) i liczę FIT na urządzenie, a potem na flotę i czas życia. Wynik porównuję z wymaganiem: czy błąd jest groźny (bezpieczeństwo, dane), czy tylko niewygodny (restart). Np. 2000 FIT to raz na kilkadziesiąt lat dla jednej karty, ale co dwa dni dla 10 000 kart w centrum danych. Zależnie od wyniku: nic, wykrywanie CRC z rekonfiguracją, korekcja CRAM w działaniu, ECC na pamięciach, TMR na krytycznym sterowaniu albo układ flash lub rad-hard.
</details>

### [29.05 — Bezpieczeństwo funkcjonalne: DO-254, IEC 61508, ISO 26262](../modules/29-konfiguracja-niezawodnosc/29.05-bezpieczenstwo-funkcjonalne-do-254-iec-61508.md)

1. **Czym jest weryfikacja oparta na wymaganiach i jak ma się do pokrycia kodu?**

<details>
<summary>Odpowiedź</summary>

Każdy przypadek testowy wywodzi się z konkretnego wymagania (ma jego identyfikator) i sprawdza, czy układ je spełnia, także w warunkach brzegowych i nieprawidłowych danych; macierz śledzenia pokazuje, że każde wymaganie jest pokryte testami, a każdy test — uzasadniony wymaganiem. Pokrycie kodu mierzy się potem: niepokryty kod oznacza brakujące wymaganie, brakujący test albo kod zbędny (do usunięcia lub uzasadnienia). Pokrycie 100 % nie dowodzi poprawności — można wykonać każdą linię i nie sprawdzić żadnego wymagania; dlatego w DO-254 jest narzędziem analizy luk, nie celem.
</details>

2. **Projekt FPGA ma ASIL D. Jakie mechanizmy zastosujesz i jak pokażesz, że wystarczą?**

<details>
<summary>Odpowiedź</summary>

Najpierw sprawdzam, czy układ ma pakiet bezpieczeństwa producenta (FMEDA, podręcznik bezpieczeństwa) — bez niego ASIL D jest praktycznie nieosiągalny. Mechanizmy: wykrywanie i korekcja błędów CRAM z czasem wykrycia mniejszym niż FTTI, ECC z czyszczeniem na pamięciach, porównanie dwóch kopii toru bezpieczeństwa (lub TMR na sterowaniu), sumy kontrolne i liczniki sekwencji na interfejsach, kontrola zegara i zasilania, nadzór zewnętrzny, testy przy starcie i test okresowy samych mechanizmów. Wystarczalność pokazuje FMEDA: dla każdego bloku awaryjność × udział trybów awarii × pokrycie diagnostyczne → SPFM ≥ 99 %, LFM ≥ 90 %, PMHF < 10 FIT, a pokrycie mechanizmów potwierdza kampania wstrzykiwania błędów.
</details>

3. **Czy narzędzie syntezy trzeba kwalifikować w DO-254?**

<details>
<summary>Odpowiedź</summary>

DO-254 wymaga oceny każdego narzędzia projektowego i weryfikacyjnego. Kwalifikacja jest potrzebna, gdy wynik narzędzia nie jest niezależnie sprawdzany. Dla syntezy i implementacji typowe podejście to niezależna weryfikacja wyniku: testy w docelowym układzie oparte na wymaganiach (dla DAL A/B wymagane i tak), często uzupełnione symulacją netlisty po implementacji lub sprawdzeniem równoważności — wtedy samo narzędzie nie wymaga kwalifikacji, ale jego wersja i ustawienia są zamrożone w konfiguracji. Inaczej jest z narzędziem weryfikacyjnym, którego wynik („test zaliczony”) przyjmuje się bez dalszej kontroli — tu potrzebna jest ocena, np. historia użycia lub test samego narzędzia.
</details>

## 30 — Metodyka i warsztat inżyniera FPGA

### [30.01 — Specyfikacja i dokumentacja: diagramy blokowe i czasowe (WaveDrom)](../modules/30-warsztat-inzyniera/30.01-specyfikacja-i-dokumentacja-diagramy-blokowe-i.md)

1. **Jak zapewnisz, że adresy rejestrów w sterowniku C zgadzają się ze sprzętem?**

<details>
<summary>Odpowiedź</summary>

Jednym źródłem: mapa rejestrów opisana w formacie maszynowym (SystemRDL, IP-XACT albo własny YAML/JSON) i generator, który robi z niej dekoder lub stałe dla RTL, nagłówek C, model rejestrów dla UVM i dokumentację. Generator waliduje opis (nakładające się pola, offsety, wartości po resecie). W CI sprawdzam, że wygenerowane pliki są aktualne, a test integracyjny steruje sprzętem w symulacji wyłącznie przez wygenerowane stałe — każdy rozjazd daje błąd kompilacji albo testu, a nie godzinę szukania na płytce. Tak działa przykład z tego tematu dla `pwm_avl`.
</details>

2. **Co powinno się znaleźć w specyfikacji interfejsu bloku?**

<details>
<summary>Odpowiedź</summary>

Tabela portów z kierunkiem, szerokością, domeną zegara i stanem po resecie; protokół — nazwa i wersja standardu plus odstępstwa (np. brak `byteenable`, readLatency = 1); diagramy czasowe typowych transakcji i przypadków brzegowych (zapis w czasie zajętości, `ready = 0`, przepełnienie); opóźnienia i przepustowość w taktach; zachowanie przy resecie i błędach; relacje między zegarami i miejsca przejść między domenami. Do tego mapa rejestrów, jeśli blok je ma. Wszystko w formie, którą weryfikacja może zamienić w testy i asercje.
</details>

3. **Dlaczego diagramy czasowe opisuje się tekstem (WaveDrom), a nie rysuje?**

<details>
<summary>Odpowiedź</summary>

Tekst leży w repozytorium obok kodu, ma historię i jest przeglądany razem ze zmianą RTL — zmiana przebiegu jest widoczna w diffie. Renderuje się automatycznie w dokumentacji, więc nie ma rozjazdu „obrazek z zeszłego roku”. Edycja jest szybsza (przesunięcie impulsu o takt to zmiana znaku) i łatwo generować diagramy z symulacji lub skryptów. Rysunek z edytora graficznego jest ładniejszy, ale nikt go nie aktualizuje.
</details>

### [30.02 — Zarządzanie rdzeniami IP producenta i własnymi](../modules/30-warsztat-inzyniera/30.02-zarzadzanie-rdzeniami-ip-producenta-i-wlasnymi.md)

1. **Co z rdzenia IP producenta trzymasz w repozytorium, a co generujesz?**

<details>
<summary>Odpowiedź</summary>

W repozytorium plik parametrów (`.ip`/`.qsys` w Quartusie, `.xci`/`.bd` w Vivado) albo — najlepiej — skrypt Tcl, który tworzy IP z parametrami, plus zapis wersji narzędzia. Wygenerowany RTL, modele symulacyjne i pliki pomocnicze generuje przepływ (skrypt, CI) przed syntezą i symulacją. Dzięki temu diff pokazuje zmianę parametrów, a nie tysiące linii wygenerowanego kodu, a przy zmianie wersji narzędzia regeneracja jest jawnym krokiem z regresją. Wyjątek: gdy narzędzie do generowania nie jest dostępne w CI, można przechowywać wygenerowane pliki, ale z kontrolą, że odpowiadają parametrom.
</details>

2. **Jak współdzielisz własny blok między kilkoma projektami?**

<details>
<summary>Odpowiedź</summary>

Blok ma własne repozytorium (albo katalog w repozytorium biblioteki) z RTL, testami, specyfikacją, CI i wersjami według semver z tagami. Projekty odwołują się do konkretnej wersji — przez menedżer rdzeni (FuseSoC z plikiem `.core` i zależnością z warunkiem wersji), podmoduł git przypięty do tagu albo wewnętrzny rejestr pakietów. Zmiana niezgodna wstecz podnosi wersję główną, więc projekty aktualizują się świadomie. Nigdy nie kopiuję katalogów między projektami.
</details>

3. **Firma przechodzi na nową wersję Vivado. Jak to zrobisz w trwającym projekcie?**

<details>
<summary>Odpowiedź</summary>

Na osobnej gałęzi: sprawdzam informacje o wydaniu i listę zmian IP, aktualizuję IP (raport aktualizacji: zmienione porty i parametry), regeneruję wszystko skryptem, uruchamiam pełną regresję symulacyjną, porównuję raporty syntezy, czasu, zasobów i ostrzeżeń ze starą wersją, testuję bitstream na sprzęcie. Dopiero po tym scalam i zapisuję nową wersję narzędzia w konfiguracji projektu (i w CI). Jeśli projekt jest blisko wydania albo certyfikowany, zostaję przy starej wersji — zmiana narzędzia to zmiana konfiguracji wymagająca ponownej weryfikacji.
</details>

### [30.03 — Kontrola wersji: co commitować, a co generować](../modules/30-warsztat-inzyniera/30.03-kontrola-wersji-co-commitowac-a-co-generowac.md)

1. **Które pliki projektu Quartusa (albo Vivado) commitujesz?**

<details>
<summary>Odpowiedź</summary>

Źródła HDL i testbenche, ograniczenia (`.sdc`/`.xdc`), przypisania pinów, skrypty tworzące projekt i uruchamiające kompilację (Tcl, Makefile), pliki parametrów IP (`.ip`, `.qsys`, `.xci`, `.bd`) albo skrypty Tcl, które je tworzą, pliki inicjalizacji pamięci i ich generatory, źródła programu procesora, dokumentację. Nie commituję baz danych kompilacji (`db/`, `incremental_db/`, `.Xil/`, `*.runs`), raportów, bitstreamów (archiwizuje je CI przy wydaniu), wygenerowanego RTL IP ani plików GUI. Plik `.qsf`/`.xpr` — najlepiej generowany skryptem; jeśli zespół woli go trzymać, to z przeglądem każdej zmiany.
</details>

2. **Klient zgłasza błąd w urządzeniu sprzed roku. Jak odtworzysz dokładnie ten bitstream?**

<details>
<summary>Odpowiedź</summary>

Z układu odczytuję rejestr wersji: numer wydania i skrót commita (to dlatego się go wbudowuje). W repozytorium robię checkout tagu, z archiwum wydania biorę zapisane wersje narzędzia i IP, uruchamiam kompilację w środowisku z tą samą wersją narzędzia (kontener lub obraz maszyny) skryptem, który był częścią tagu. Wynik porównuję z archiwalnym: suma SHA-256 bitstreamu (jeśli kompilacja jest bit w bit powtarzalna) albo przynajmniej raporty czasowe i zasobów. Jeśli archiwum zawiera sam bitstream, mogę go od razu wgrać na płytkę testową i odtworzyć błąd.
</details>

3. **Dlaczego projekt tworzony skryptem jest lepszy niż `.qsf` edytowany w GUI?**

<details>
<summary>Odpowiedź</summary>

Skrypt jest krótki i czytelny, a jego zmiany widać w diffie i przeglądzie — `.qsf` zapisywany przez GUI miesza ustawienia, kolejność zmienia się przy każdym zapisie, a przypadkowe kliknięcia trafiają do repozytorium. Skrypt działa tak samo w CI i u każdego członka zespołu, ułatwia przejście na nową wersję narzędzia i budowanie wariantów (parametry, inne układy). Wspólne części — przypisania pinów płytki, ustawienia zegarów — można dołączać z jednego pliku do wielu projektów, jak `plytka-deca/deca_piny.tcl` w tym repozytorium.
</details>

### [30.04 — Praca w zespole: przeglądy kodu, standardy i sign-off](../modules/30-warsztat-inzyniera/30.04-praca-w-zespole-przeglady-kodu-standardy-i-sign.md)

1. **Na co zwracasz uwagę, przeglądając czyjś kod RTL?**

<details>
<summary>Odpowiedź</summary>

Zakładam, że CI (testy, lint, synteza) jest zielone, więc nie szukam błędów składni. Sprawdzam zgodność ze specyfikacją i przypadki brzegowe (przepełnienia, `ready = 0`, zapis w czasie zajętości), przejścia między domenami zegara i ich synchronizatory, resety (zwolnienie synchroniczne, które rejestry), automaty (stany niedozwolone, wyjścia w każdym stanie), szerokości i arytmetykę ze znakiem, czy testbench sprawdza przypadki brzegowe, czy jest samosprawdzający, jak zmiana wpływa na zasoby i czas (raport). Na końcu czytelność: nazwy, komentarze „dlaczego”, brak magicznych stałych. Komentarze dzielę na obowiązkowe i sugestie.
</details>

2. **Co musi być spełnione, żebyś podpisał wydanie bitstreamu?**

<details>
<summary>Odpowiedź</summary>

Bitstream zbudowany przez CI z oznaczonego tagu, z wersją i skrótem commita w układzie. Pełna regresja symulacyjna PASS, cele pokrycia osiągnięte, testy na sprzęcie dla tej wersji z protokołem. Czas: dodatni zapas setup i hold we wszystkich narożnikach, brak ścieżek bez ograniczeń, każdy wyjątek czasowy przejrzany, raport CDC bez niewyjaśnionych przejść. Ostrzeżenia krytyczne wyjaśnione, zasoby i moc w budżecie, piny zgodne ze schematem. Odstępstwa na piśmie. Archiwum z bitstreamem, raportami, sumami i wersjami narzędzi.
</details>

3. **Recenzent odrzuca Twoją zmianę z komentarzem, z którym się nie zgadzasz. Co robisz?**

<details>
<summary>Odpowiedź</summary>

Najpierw upewniam się, że rozumiem zarzut — dopytuję, jaki scenariusz recenzent ma na myśli; często komentarz wskazuje realny problem, tylko inaczej nazwany. Jeśli nadal się nie zgadzam, odpowiadam merytorycznie: odwołanie do specyfikacji, wynik testu albo symulacji, który pokazuje zachowanie w tym przypadku, ewentualnie dodaję test, który rozstrzyga sprawę. Jeśli to kwestia gustu, a nie poprawności, odwołuję się do standardu kodowania; jeśli standard milczy — proponuję uzupełnić go, zamiast spierać się w każdym przeglądzie. Przy braku porozumienia decyduje prowadzący, a ustalenie zapisujemy.
</details>

### [30.05 — Kariera w FPGA: role, branże i ścieżki rozwoju](../modules/30-warsztat-inzyniera/30.05-kariera-w-fpga-role-branze-i-sciezki-rozwoju.md)

1. **Opowiedz o projekcie FPGA, z którego jesteś najbardziej zadowolony.**

<details>
<summary>Odpowiedź</summary>

Struktura odpowiedzi (2–3 minuty, potem pytania): problem i wymagania (liczby: przepustowość, opóźnienie, zegar, zasoby), architektura i najważniejsza decyzja z alternatywami, które odrzuciłem i dlaczego, jak weryfikowałem (testbench, pokrycie, test na sprzęcie), najtrudniejszy błąd — jak się objawiał, jak go znalazłem, czego mnie nauczył, wynik (zasoby, zapas czasowy, działanie) i co zrobiłbym inaczej. Rekruter ocenia głębokość zrozumienia i samodzielność, więc mówię o swoich decyzjach, a nie o tym, co zrobił zespół.
</details>

2. **Dlaczego FPGA, a nie oprogramowanie albo ASIC?**

<details>
<summary>Odpowiedź</summary>

Odpowiedź osobista, ale dobrze, jeśli pokazuje rozumienie miejsca FPGA: współbieżność i deterministyczne opóźnienie, których nie da procesor; elastyczność i krótki cykl zmian, których nie da ASIC (projekt ASIC trwa latami i kosztuje miliony na maski); bezpośredni kontakt ze sprzętem i fizyką sygnałów. Do tego to, co konkretnie lubię w tej pracy: np. zamykanie czasu, debugowanie na sprzęcie, przekładanie algorytmu na potok — najlepiej z przykładem z własnego projektu.
</details>

3. **Czym różni się praca inżyniera weryfikacji od projektanta RTL?**

<details>
<summary>Odpowiedź</summary>

Projektant buduje blok, który spełnia specyfikację w zadanych zasobach i czasie; myśli o architekturze, potokach, czasie i implementacji. Weryfikator próbuje wykazać, że blok nie spełnia specyfikacji: buduje środowisko testowe (UVM, cocotb), modele odniesienia, generatory losowe z ograniczeniami, asercje, pokrycie funkcjonalne, dowody formalne, prowadzi regresje i analizuje luki. Pracuje ze specyfikacji, nie z kodu, i potrzebuje silnych umiejętności programistycznych. Obie role się przenikają — dobry projektant pisze testy i asercje, dobry weryfikator czyta RTL i raporty.
</details>

## 31 — Projekty końcowe na DECA

### [31.01 — Projekt 1: zegar i stoper sterowany komendami przez UART](../modules/31-projekty-koncowe/31.01-projekt-1-zegar-i-stoper-sterowany-komendami.md)

1. **Dlaczego liczniki zegara w BCD, a nie binarne?**

<details>
<summary>Odpowiedź</summary>

Bo wynik trafia do człowieka jako cyfry dziesiętne: znaki ASCII to `0x30 | cyfra`, wyświetlacze 7-segmentowe dekodują cyfrę wprost. Licznik binarny wymagałby konwersji (dzielenie przez 10 albo algorytm double dabble) przy każdym wysłaniu. BCD kosztuje kilka LUT na cyfrę (porównanie z 9/5 i przeniesienie), a logika zostaje prosta i szybka.
</details>

2. **Jak zweryfikowałbyś interpreter komend tekstowych?**

<details>
<summary>Odpowiedź</summary>

Testbench zachowuje się jak terminal: nadaje bajty szeregowo w formacie łącza, odbiera odpowiedzi drugą linią, składa linie i porównuje je ze wzorcem. Pokrywam każdą komendę, błędy formatu i zakresu, wielkie i małe litery, przypadki brzegowe stanu (północ, przepełnienie stopera), sytuacje współbieżne (komenda w trakcie odpowiedzi). Czas przyspieszam parametrami, a wartości zależne od czasu porównuję z tolerancją wynikającą z fazy dzielnika. Ten sam test w trzech symulatorach daje pewność, że nie zależy od kolejności zdarzeń.
</details>

3. **Co się stanie, gdy dwie komendy przyjdą jedna po drugiej, a odpowiedź na pierwszą jeszcze wychodzi? Jak inaczej można to rozwiązać?**

<details>
<summary>Odpowiedź</summary>

W tym projekcie druga komenda jest wykonana, ale jej odpowiedź przepada i ustawia się lepka flaga — świadomy kompromis dla protokołu zapytanie–odpowiedź. Inne rozwiązania: kolejka FIFO bajtów wyjściowych (koszt: pamięć i logika, ale żadna odpowiedź nie ginie), kolejka komend wejściowych (opóźnione wykonanie) albo sterowanie przepływem (RTS/CTS, XON/XOFF), żeby nadawca czekał. Wybór zależy od tego, czy kolejność i kompletność odpowiedzi są ważne dla protokołu.
</details>

### [31.02 — Projekt 2: oscyloskop na wbudowanym ADC z obrazem przez HDMI](../modules/31-projekty-koncowe/31.02-projekt-2-oscyloskop-na-wbudowanym-adc-z.md)

1. **Jak przekażesz zrzut 512 próbek z domeny zegara ADC do domeny zegara piksela?**

<details>
<summary>Odpowiedź</summary>

Próbki zapisuję do pamięci dwuportowej z dwoma zegarami — każdy port pracuje w swojej domenie, więc same dane nie przechodzą przez logikę CDC. Przez granicę idzie tylko informacja „zrzut gotowy w banku B od adresu P”: B i P są stabilne, przełącznik `gotowy_t` przechodzi przez synchronizator dwóch przerzutników, odbiorca czyta B i P i odsyła przełącznik `potw_t`. Do czasu potwierdzenia nadawca nie zmienia B ani P i pisze tylko do drugiego banku. Alternatywa to asynchroniczna FIFO, ale przy dostępie losowym (rysowanie kolumn) pamięć z dwoma bankami jest prostsza.
</details>

2. **Dlaczego oscyloskop potrzebuje podglądu przed wyzwoleniem i jak go zrealizować w FPGA?**

<details>
<summary>Odpowiedź</summary>

Często interesuje nas, co doprowadziło do zdarzenia (np. zakłócenie przed zboczem). Realizacja: zapis ciągły do pamięci kołowej, a po wyzwoleniu tylko `N − PRZED − 1` próbek więcej; początek zrzutu to adres wyzwolenia minus `PRZED`. Trzeba też zebrać pierwsze `PRZED` próbek przed uzbrojeniem, inaczej pierwszy zrzut zawiera nieważne dane.
</details>

3. **Czym jest tryb auto i dlaczego jest potrzebny?**

<details>
<summary>Odpowiedź</summary>

W trybie normalnym zrzut powstaje tylko po wyzwoleniu, więc stały sygnał albo sygnał poza poziomem wyzwalania daje pusty ekran. Tryb auto po określonym czasie bez wyzwolenia robi zrzut „na siłę”, żeby użytkownik widział, co się dzieje, i mógł ustawić poziom. W tym projekcie licznik `AUTO` próbek w stanie uzbrojenia i flaga `wyzwolony` informują, skąd pochodzi zrzut.
</details>

### [31.03 — Projekt 3: syntezator dźwięku sterowany przez UART lub MIDI](../modules/31-projekty-koncowe/31.03-projekt-3-syntezator-dzwieku-sterowany-przez.md)

1. **Jak obliczysz krok akumulatora fazy dla danej częstotliwości i jak dokładna jest wynikowa częstotliwość?**

<details>
<summary>Odpowiedź</summary>

krok = round(f · 2^N / fs). Przy N = 24 i fs = 48 828 Hz rozdzielczość to fs / 2^N ≈ 2,9 mHz, więc błąd zaokrąglenia kroku jest pomijalny (dla 440 Hz poniżej 0,001 %). W tym projekcie kroki dla oktaw niższych powstają przesunięciem kroku z najwyższej oktawy — to dodatkowo obcina bity, ale przy 24 bitach błąd zostaje w setnych częściach centa. Faktyczna dokładność zależy od oscylatora płytki (np. 50 ppm).
</details>

2. **Co to jest running status w MIDI i jak wpływa na dekoder?**

<details>
<summary>Odpowiedź</summary>

Nadajnik może pominąć bajt statusu, jeśli jest taki sam jak w poprzednim komunikacie kanałowym; odbiornik musi pamiętać ostatni status i traktować bajt danych jako początek nowego komunikatu. Dekoder trzyma więc rejestr statusu, kasuje go przy komunikatach systemowych `F0`–`F7`, nie zmienia przy komunikatach czasu rzeczywistego `F8`–`FF` (te mogą wejść nawet między bajty danych) i liczy bajty danych według typu komunikatu (1 albo 2).
</details>

3. **Masz 4 głosy i jedną mnożarkę. Jak policzysz wszystkie w czasie jednej próbki i ile głosów zmieścisz maksymalnie?**

<details>
<summary>Odpowiedź</summary>

Multipleksuję w czasie: głosy liczone są po kolei, każdy w kilku taktach (tu 4: ADSR i faza, kształt, × obwiednia, × prędkość z akumulacją). Przy 12,5 MHz i fs = 48,8 kHz jest 256 taktów na próbkę, więc teoretycznie 64 głosy po 4 takty. Ograniczeniem staje się wtedy stan głosów (faza, obwiednia, nuta — ok. 60 bitów na głos), który zamiast w rejestrach warto trzymać w pamięci blokowej, oraz zakres sumy.
</details>

### [31.04 — Projekt 4: system z Nios V, DDR3 i strumieniem UDP](../modules/31-projekty-koncowe/31.04-projekt-4-system-z-nios-v-ddr3-i-strumieniem-udp.md)

1. **Jak zaprojektujesz master Avalon-MM czytający blok danych z DDR3 tak, żeby nigdy nie zgubić danych?**

<details>
<summary>Odpowiedź</summary>

Żądanie liczę jako przyjęte tylko przy `read && !waitrequest`; adres i liczba słów zmieniają się dopiero wtedy. Dane przychodzą z `readdatavalid` w kolejności żądań, ale z dowolnym opóźnieniem, a odbiorca nie może ich wstrzymać, więc muszę mieć na nie miejsce: liczę odczyty w locie i słowa w buforze i zlecam nowy odczyt tylko wtedy, gdy ich suma jest mniejsza od pojemności bufora. Dla wydajności używam burstów (`burstcount`) i dłuższego bufora; testbench z losowym `waitrequest` i opóźnieniem sprawdza, że wynik jest bitowo zgodny z pamięcią.
</details>

2. **Dlaczego peryferium buforuje całą ramkę przed wysłaniem przez MII?**

<details>
<summary>Odpowiedź</summary>

MII ma stały rytm 25 MHz × 4 bity i nie pozwala na przerwę w środku ramki: `tx_en` musi trwać bez przerwy od preambuły do FCS. Źródło danych (DDR3 z odświeżaniem, magistrala współdzielona z procesorem) może się wstrzymać na nieprzewidywalny czas. Buforując całą ramkę (do 1518 B) w kolejce asynchronicznej, oddzielam niedeterministyczny odczyt od deterministycznego nadawania i przy okazji przechodzę między domenami zegara. Alternatywa: bufor tylko częściowy z gwarancją przepustowości i najgorszego opóźnienia pamięci — tańszy, ale trudniejszy do udowodnienia.
</details>

3. **Jak podzielisz pracę między procesor a sprzęt w strumieniu UDP o przepustowości bliskiej 100 Mb/s?**

<details>
<summary>Odpowiedź</summary>

Wszystko, co dotyczy każdego bajtu (odczyt bufora, sumy kontrolne, FCS, nadawanie), robi sprzęt; procesor zajmuje się tym, co rzadkie: konfiguracją adresów i portów, przygotowaniem bufora, decyzją, kiedy wysłać, obsługą błędów i ARP. Procesor 50–100 MHz nie nadąży kopiować 12 MB/s bajt po bajcie, a jedno zlecenie na ramkę to kilkanaście instrukcji. Kolejne usprawnienie to podwójne bufory (procesor wypełnia jeden, sprzęt wysyła drugi) albo kolejka deskryptorów, żeby sprzęt nie czekał na procesor między ramkami.
</details>

### [31.05 — Projekt 5: przetwarzanie obrazu z kamery MIPI w czasie rzeczywistym](../modules/31-projekty-koncowe/31.05-projekt-5-przetwarzanie-obrazu-z-kamery-mipi-w.md)

1. **Jak zrealizujesz filtr 3 × 3 na strumieniu wideo bez bufora ramki?**

<details>
<summary>Odpowiedź</summary>

Dwa bufory linii (pamięć na jedną linię każdy) opóźniają strumień o 1 i 2 linie; z trzech strumieni (bieżący, −1, −2 linie) w rejestrach przesuwnych po 3 próbki powstaje okno 3 × 3, które przesuwa się o piksel na takt. Wynik ma opóźnienie ok. jednej linii i kilku taktów, a sygnały synchronizacji muszą być opóźnione tak samo. Brzegi obsługuje się powielaniem albo zerami. Pamięć: (k − 1) × długość linii × szerokość piksela — dla 3 × 3 przy 640 px i 8 bitach to 2 bloki M9K.
</details>

2. **Na czym polega demozaikowanie i jakie artefakty daje metoda dwuliniowa?**

<details>
<summary>Odpowiedź</summary>

Czujnik z filtrem Bayera mierzy w każdym pikselu tylko jedną składową; demozaikowanie odtwarza dwie brakujące z sąsiadów. Metoda dwuliniowa bierze średnią najbliższych sąsiadów danej barwy (krzyż, przekątne, pary poziome lub pionowe). Jest tania (okno 3 × 3, same sumy), ale na ostrych krawędziach daje kolorowe obwódki i efekt „zamka błyskawicznego”, bo uśrednia przez krawędź. Lepsze metody (Malvar–He–Cutler, metody kierunkowe) korzystają z gradientu zielonej składowej i większego okna.
</details>

3. **Jak zmienisz tryb potoku wideo w trakcie pracy, żeby nie zepsuć obrazu?**

<details>
<summary>Odpowiedź</summary>

Rejestr trybu z wejścia (przycisk, rejestr procesora) jest zatrzaskiwany w rejestrze roboczym tylko na początku wygaszania pionowego — tu na zboczu `vs` najpóźniejszej ścieżki, kiedy żadna ścieżka nie niesie pikseli aktywnych. Jeśli wejście przychodzi z innej domeny zegara, najpierw synchronizator (dla wielobitowego — przekazanie z potwierdzeniem). Dodatkowo wszystkie ścieżki multipleksera mają takie samo opóźnienie, więc przełączenie nie przesuwa obrazu.
</details>

### [31.06 — Projekt 6: własny procesor RISC-V z peryferiami](../modules/31-projekty-koncowe/31.06-projekt-6-wlasny-procesor-risc-v-z-peryferiami.md)

1. **Jak podłączysz peryferium do własnego procesora i na co uważać przy odczycie rejestrów?**

<details>
<summary>Odpowiedź</summary>

Mapuję je w przestrzeni adresowej: dekoder po najstarszych bitach adresu wybiera RAM albo peryferium, zapis idzie do rejestru przy `wstrb != 0`, a dane odczytu wybiera multiplekser. Najważniejsze, żeby odczyt peryferium miał dokładnie taką samą latencję jak RAM (tu 1 takt, wybór źródła w stopniu zapisu wyniku), inaczej rdzeń dostanie złe dane. Odczyty z efektem ubocznym (zdejmowanie bajtu z kolejki, kasowanie flagi) mogą się wykonać tylko raz i tylko dla instrukcji, które naprawdę zostaną zatwierdzone — w potoku odczyt musi być po rozstrzygnięciu skoków albo peryferium musi tolerować spekulację.
</details>

2. **Program ma zmieniać LED co 0,25 s, ale w międzyczasie obsługuje UART. Jak zapewnić równe odstępy?**

<details>
<summary>Odpowiedź</summary>

Liczenie czasu oddaję sprzętowi: licznik swobodny i rejestr porównania ustawiający flagę (albo przerwanie). Następne porównanie wyliczam jako poprzednie + okres, a nie licznik + okres, więc opóźnienie obsługi flagi wpływa tylko na chwilę reakcji, a nie na kolejne odstępy (brak dryfu). Pierwsze porównanie ustawiam tuż przed pętlą główną, po długich operacjach inicjalizacji. Jeśli obsługa może się spóźnić o cały okres, stosuję porównanie ze znakiem różnicy zamiast równości.
</details>

3. **Jak weryfikujesz jednocześnie sprzęt i program w takim mikrokontrolerze?**

<details>
<summary>Odpowiedź</summary>

Testbench systemowy uruchamia RTL z prawdziwym programem złożonym z repozytorium i sprawdza zachowanie na zewnętrznych wyprowadzeniach: dekoduje UART, mierzy PWM i odstępy LED, wysyła znaki i porównuje echo, a koniec programu sygnalizuje zapis TOHOST. Stałe czasowe w wariancie symulacyjnym są skrócone, logika ta sama. Do tego testy jednostkowe rdzenia (moduł 27: zestaw instrukcji, hazardy) i peryferiów osobno oraz sprawdzenie w CI, że plik programu odpowiada źródłu. Błąd znaleziony tu (odstęp 1987 zamiast 3000) był błędem programu, nie sprzętu — test systemowy wykrywa oba rodzaje.
</details>
