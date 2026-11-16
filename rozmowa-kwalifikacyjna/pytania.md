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
