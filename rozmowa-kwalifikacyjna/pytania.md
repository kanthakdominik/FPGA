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
