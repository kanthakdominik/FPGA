# Pułapki i pytania podchwytliwe

[← rozmowa kwalifikacyjna](README.md)

> **Status:** ✅ pełny

Pytania, na które kandydaci najczęściej odpowiadają szybko i źle — zwykle dlatego, że zapamiętali regułę bez powodu, dla którego obowiązuje. Format: pytanie · częsta błędna odpowiedź · jak jest naprawdę · temat w bazie, gdzie jest pełne wyjaśnienie z kodem.

Jak tego używać: zasłoń dwie ostatnie linijki i odpowiedz na głos, jak na rozmowie — razem z uzasadnieniem i przykładem. Jeśli odpowiedź mieści się w jednym zdaniu, prawie na pewno jest za krótka.

## Język: VHDL, Verilog, SystemVerilog

### 1. Czym różni się przypisanie blokujące od nieblokującego?

- **Częsta błędna odpowiedź:** „Nieblokujące daje przerzutnik, blokujące — logikę kombinacyjną.”
- **Jak jest naprawdę:** to, czy powstaje przerzutnik, wynika z tego, czy blok jest wyzwalany zboczem. Rodzaj przypisania decyduje o **kolejności aktualizacji** w symulatorze: blokujące zmienia zmienną od razu (następna instrukcja widzi nową wartość), nieblokujące — na końcu kroku czasowego. W bloku zegarowym blokujące może dać rejestr albo nie, zależnie od kolejności instrukcji, i tworzy wyścigi między blokami. Reguła `<=` w blokach sekwencyjnych i `=` w kombinacyjnych chroni przed niezgodnością symulacji i sprzętu.
- **Temat:** [05.04](../modules/05-verilog/05.04-przypisania-blokujace-i-nieblokujace-reguly.md)

### 2. Skąd biorą się niezamierzone zatrzaski?

- **Częsta błędna odpowiedź:** „Z każdego `if` bez `else`.”
- **Jak jest naprawdę:** z **bloku kombinacyjnego**, w którym istnieje ścieżka nieprzypisująca wartości któremuś wyjściu — układ musi wtedy „pamiętać” poprzednią wartość. W bloku zegarowym `if` bez `else` jest w porządku: daje przerzutnik z zezwoleniem. Zapobieganie: wartości domyślne na początku bloku kombinacyjnego, `always_comb` (narzędzie ostrzeże), pełne `case` z `default`.
- **Temat:** [07.03](../modules/07-kodowanie-pod-synteze/07.03-niezamierzone-zatrzaski-i-petle-kombinacyjne.md)

### 3. Co się stanie, gdy w liście wrażliwości procesu kombinacyjnego zabraknie sygnału?

- **Częsta błędna odpowiedź:** „Syntezator zrobi zatrzask.” albo „Nic, bo to tylko symulacja.”
- **Jak jest naprawdę:** synteza zwykle ignoruje listę wrażliwości (z ostrzeżeniem) i buduje zwykłą logikę kombinacyjną, a symulator nie przelicza procesu przy zmianie brakującego sygnału — **symulacja i sprzęt zachowują się inaczej**. Dlatego `always @*` / `always_comb` w Verilogu i SystemVerilogu oraz `process (all)` w VHDL-2008.
- **Temat:** [04.04](../modules/04-vhdl/04.04-procesy-lista-wrazliwosci-sygnaly-a-zmienne.md)

### 4. Sygnał a zmienna w VHDL — który daje rejestr?

- **Częsta błędna odpowiedź:** „Sygnał to przewód, zmienna to rejestr.” (albo odwrotnie)
- **Jak jest naprawdę:** zmienna zmienia się natychmiast, sygnał — po zakończeniu procesu (w następnym cyklu delta). W procesie zegarowym sygnał zawsze daje przerzutnik; zmienna daje przerzutnik tylko wtedy, gdy jest **czytana przed zapisem** (musi pamiętać wartość z poprzedniego taktu), a gdy jest zapisywana przed odczytem — samą logikę kombinacyjną.
- **Temat:** [04.04](../modules/04-vhdl/04.04-procesy-lista-wrazliwosci-sygnaly-a-zmienne.md)

### 5. Jak dodać dwa `std_logic_vector` w VHDL?

- **Częsta błędna odpowiedź:** „Dołączyć `ieee.std_logic_unsigned` i po prostu dodać.”
- **Jak jest naprawdę:** `std_logic_unsigned` i `std_logic_arith` to niestandardowe pakiety firmy Synopsys — w nowym kodzie się ich nie używa. Liczby mają typy `unsigned` i `signed` z `ieee.numeric_std`; to typ mówi, czy liczba ma znak, a konwersje są jawne: `std_logic_vector(unsigned(a) + unsigned(b))`.
- **Temat:** [04.02](../modules/04-vhdl/04.02-typy-std-logic-wektory-numeric-std-integer-typy.md), [04.09](../modules/04-vhdl/04.09-pulapki-vhdl-rozdzielczosc-sygnalow-konwersje-i.md)

### 6. Jaką szerokość i znak ma wynik `a + b` w Verilogu?

- **Częsta błędna odpowiedź:** „Szerokość większego argumentu i znak, jeśli którykolwiek ma znak.”
- **Jak jest naprawdę:** szerokość wyznacza **kontekst** — największa z szerokości argumentów i lewej strony przypisania (przeniesienie zostaje, jeśli lewa strona jest szersza). Wyrażenie jest ze znakiem tylko wtedy, gdy **wszystkie** argumenty są ze znakiem; jeden argument bez znaku (także literał `8'd5` albo wycinek `a[7:0]`) czyni całe wyrażenie bez znaku i rozszerzenie zerami zamiast znakiem. Pomaga `$signed()` i jawne rozszerzanie.
- **Temat:** [05.02](../modules/05-verilog/05.02-operatory-liczby-rozmiar-i-znak.md), [05.07](../modules/05-verilog/05.07-pulapki-verilogu-niejawne-sieci-obcinanie-znak.md)

### 7. Czym różni się `==` od `===`? Którego używać w RTL?

- **Częsta błędna odpowiedź:** „`===` jest dokładniejsze, więc lepsze.”
- **Jak jest naprawdę:** `==` daje `x`, gdy któryś bit jest `x` lub `z`; `===` porównuje dosłownie, łącznie z `x` i `z`, i zawsze daje 0 albo 1. W sprzęcie nie ma stanu `x`, więc `===` nie ma odpowiednika — w RTL `==`, w testbenchu `!==` do sprawdzania wyników, bo wykrywa niezainicjalizowane wyjście (`x !== 1` jest prawdą, a `x != 1` daje `x` i warunek się nie wykona).
- **Temat:** [05.02](../modules/05-verilog/05.02-operatory-liczby-rozmiar-i-znak.md)

### 8. Co zrobi kompilator Veriloga z literówką w nazwie sygnału?

- **Częsta błędna odpowiedź:** „Zgłosi błąd, że sygnał nie istnieje.”
- **Jak jest naprawdę:** w połączeniach portów i w `assign` utworzy **niejawną sieć 1-bitową** i skompiluje się bez błędu. Na początku każdego pliku `` `default_nettype none `` — wtedy niezadeklarowana nazwa jest błędem.
- **Temat:** [05.07](../modules/05-verilog/05.07-pulapki-verilogu-niejawne-sieci-obcinanie-znak.md)

### 9. Pętla `for` w kodzie RTL — ile taktów trwa?

- **Częsta błędna odpowiedź:** „Jeden obrót pętli na takt.”
- **Jak jest naprawdę:** zero — pętla jest **rozwijana** w syntezie w równoległy sprzęt działający w jednym takcie (np. 32 komparatory albo łańcuch sumatorów). Liczba obrotów musi być znana w czasie syntezy. Coś, co ma trwać wiele taktów, opisuje się licznikiem i automatem.
- **Temat:** [07.01](../modules/07-kodowanie-pod-synteze/07.01-myslenie-sprzetowe-kod-hdl-to-schemat-nie.md)

### 10. Czy `unique case` w SystemVerilogu to tylko komentarz dla syntezy?

- **Częsta błędna odpowiedź:** „Tak, wskazówka bez skutków.”
- **Jak jest naprawdę:** to obietnica, że dokładnie jedna gałąź pasuje. Symulator sprawdza ją i zgłasza naruszenie, a synteza **wykorzystuje** ją do uproszczenia logiki (jak dawne `parallel_case` / `full_case`). Fałszywa obietnica daje układ, który w sprzęcie działa inaczej niż w symulacji bez ostrzeżeń — dlatego naruszeń nie wolno ignorować.
- **Temat:** [06.05](../modules/06-systemverilog-rtl/06.05-unique-priority-i-bezpieczne-instrukcje-case.md)

## Czas i zegary

### 11. Masz naruszenie czasu hold. Obniżysz częstotliwość zegara?

- **Częsta błędna odpowiedź:** „Tak, wolniejszy zegar daje więcej czasu.”
- **Jak jest naprawdę:** hold porównuje dane i zegar **na tym samym zboczu**, więc okres zegara w ogóle nie występuje w równaniu — naruszenie zostanie przy każdej częstotliwości. Naprawia się je opóźnieniem ścieżki danych (narzędzie robi to samo przy trasowaniu) albo zmniejszeniem przesunięcia zegara. Hold po trasowaniu zwykle świadczy o złym ograniczeniu albo o zegarze z logiki.
- **Temat:** [14.01](../modules/14-analiza-czasowa/14.01-sciezki-czasowe-setup-hold-i-zapas-slack.md)

### 12. Raport pokazuje ujemny zapas setup, ale układ na płytce działa. Zostawić?

- **Częsta błędna odpowiedź:** „Skoro działa, to raport jest zbyt ostrożny.”
- **Jak jest naprawdę:** analiza dotyczy najgorszych warunków (wolny proces, niskie napięcie, wysoka temperatura) — płytka na biurku jest w dobrych warunkach. Ten sam bitstream może zawodzić w obudowie latem albo na innym egzemplarzu układu. Projekt z ujemnym zapasem nie jest skończony; naprawa: potokowanie, mniejszy fanout, inna architektura, poprawne wyjątki.
- **Temat:** [14.05](../modules/14-analiza-czasowa/14.05-czytanie-raportow-timing-analyzer-i-vivado.md), [16.04](../modules/16-wydajnosc-zasoby-moc/16.04-zamykanie-timingu-metodyka-krok-po-kroku.md)

### 13. Czy przesunięcie zegara (skew) zawsze szkodzi?

- **Częsta błędna odpowiedź:** „Tak, idealnie powinno być zero.”
- **Jak jest naprawdę:** zegar docierający do odbiorcy **później** niż do nadawcy daje danym więcej czasu na setup, ale zabiera zapas hold; wcześniejszy — odwrotnie. Narzędzia czasem celowo przesuwają zegar (useful skew). Szkodzi skew nieprzewidywalny i nieuwzględniony w analizie — taki, jak przy zegarze z logiki.
- **Temat:** [14.02](../modules/14-analiza-czasowa/14.02-zegar-w-praktyce-skew-jitter-i-niepewnosc.md)

### 14. Potrzebujesz zegara 1 MHz z 50 MHz. Licznik i jego wyjście jako zegar?

- **Częsta błędna odpowiedź:** „Tak, najprostszy dzielnik.”
- **Jak jest naprawdę:** zegar z logiki nie idzie siecią globalną, ma duże i zmienne przesunięcie, może mieć zakłócenia i tworzy nową domenę zegarową (CDC z każdym sygnałem z 50 MHz). W FPGA robi się to **impulsem zezwolenia** (clock enable) co 50 taktów przy jednym zegarze, a prawdziwy inny zegar — w PLL.
- **Temat:** [15.01](../modules/15-zegary-reset-cdc/15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md), [07.04](../modules/07-kodowanie-pod-synteze/07.04-liczniki-dzielniki-i-clock-enable.md)

### 15. Bramkowanie zegara oszczędza moc. Napiszesz `assign gclk = clk & en;`?

- **Częsta błędna odpowiedź:** „Tak, to standardowa technika.”
- **Jak jest naprawdę:** w ASIC robi się to komórką z zatrzaskiem (ICG), a w FPGA bramka w torze zegara daje zakłócenia, gdy `en` zmienia się przy wysokim zegarze, i przesunięcie zegara. W FPGA: dedykowany bufor zegara z zezwoleniem (ALTCLKCTRL, BUFGCE) albo zwykłe zezwolenie na przerzutnikach.
- **Temat:** [15.01](../modules/15-zegary-reset-cdc/15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md)

### 16. Narzędzie nie zgłasza błędów czasowych, a część ścieżek jest bez ograniczeń. W porządku?

- **Częsta błędna odpowiedź:** „Tak, brak błędów to brak problemów.”
- **Jak jest naprawdę:** ścieżka bez ograniczenia **nie jest analizowana**, więc nie może mieć błędu. Raport ścieżek nieograniczonych (unconstrained paths) musi być pusty: każdy zegar opisany, każde wejście i wyjście z `set_input_delay` / `set_output_delay` albo jawnym wyjątkiem.
- **Temat:** [14.03](../modules/14-analiza-czasowa/14.03-ograniczenia-sdc-zegary-zegary-generowane.md), [03.04](../modules/03-przeplyw-projektowy/03.04-raporty-zasoby-czasy-i-ostrzezenia-ktorych-nie.md)

### 17. Sygnały między domenami zegarowymi — wystarczy `set_false_path`?

- **Częsta błędna odpowiedź:** „Tak, ścieżek między asynchronicznymi zegarami nie da się analizować, więc false path.”
- **Jak jest naprawdę:** wyjątek tylko wyłącza analizę — nie zastępuje synchronizatora. Dla wskaźników w kodzie Graya i magistral z handshakiem potrzebne jest `set_max_delay -datapath_only` (albo ograniczenie przesunięcia między bitami), bo opóźnienie ścieżki nadal ma znaczenie. False path bez struktury CDC tylko ukrywa błąd przed narzędziem.
- **Temat:** [15.07](../modules/15-zegary-reset-cdc/15.07-ograniczenia-i-weryfikacja-cdc.md), [14.04](../modules/14-analiza-czasowa/14.04-wyjatki-false-path-multicycle-max-min-delay.md)

## CDC i reset

### 18. Czy dwa przerzutniki synchronizatora wystarczą zawsze?

- **Częsta błędna odpowiedź:** „Tak, to standard.”
- **Jak jest naprawdę:** tylko dla **jednego bitu**, który trwa dłużej niż okres zegara docelowego. Krótki impuls z szybszej domeny może zniknąć między zboczami (potrzebny przełącznik albo handshake), a słowo przeniesione bit po bicie może się rozjechać. Przy bardzo szybkich zegarach rachunek MTBF może wymagać trzeciego stopnia.
- **Temat:** [15.02](../modules/15-zegary-reset-cdc/15.02-metastabilnosc-i-mtbf-rachunek.md), [15.03](../modules/15-zegary-reset-cdc/15.03-synchronizatory-jednobitowe-i-synchronizacja.md)

### 19. Jak przenieść wartość licznika binarnego do innej domeny?

- **Częsta błędna odpowiedź:** „Każdy bit przez synchronizator.”
- **Jak jest naprawdę:** przy przejściu 0111 → 1000 zmieniają się cztery bity; każdy może zostać złapany w innym takcie, więc odbiorca zobaczy wartość, której nigdy nie było (np. 1111). Licznik w **kodzie Graya** (jeden bit na krok — odczyt jest starą albo nową wartością) albo handshake z danymi stabilnymi do potwierdzenia.
- **Temat:** [15.04](../modules/15-zegary-reset-cdc/15.04-przesylanie-slow-handshake-kod-graya-i-mcp.md)

### 20. Reset asynchroniczny jest bezpieczny, bo działa bez zegara?

- **Częsta błędna odpowiedź:** „Tak, dlatego jest lepszy.”
- **Jak jest naprawdę:** **włączenie** resetu może być asynchroniczne, ale **zwolnienie** musi być zsynchronizowane z zegarem (synchronizator resetu). Zwolnienie blisko zbocza narusza czasy recovery/removal — część przerzutników wyjdzie z resetu takt wcześniej, a automat może wystartować w nielegalnym stanie.
- **Temat:** [15.06](../modules/15-zegary-reset-cdc/15.06-strategie-resetu-synchronizator-resetu-i-rdc.md)

### 21. Czy każdy przerzutnik powinien mieć reset?

- **Częsta błędna odpowiedź:** „Tak, dla bezpieczeństwa.”
- **Jak jest naprawdę:** w FPGA każdy przerzutnik ma wartość początkową z konfiguracji. Reset jest potrzebny tam, gdzie stan ma znaczenie (automaty, liczniki, flagi `valid`), a na ścieżce danych zwykle nie. Zbędny reset zwiększa fanout sygnału resetu (problemy czasowe) i uniemożliwia upakowanie logiki w rejestry przesuwne, bloki DSP i pamięci.
- **Temat:** [07.02](../modules/07-kodowanie-pod-synteze/07.02-rejestry-i-reset-synchroniczny-asynchroniczny.md)

### 22. Czy symulacja wykaże problem z metastabilnością?

- **Częsta błędna odpowiedź:** „Tak, pojawi się `x`.”
- **Jak jest naprawdę:** symulator RTL nie modeluje metastabilności — przerzutnik zawsze przyjmie 0 albo 1, a test przejdzie. Błędy CDC wykrywa analiza strukturalna (narzędzia CDC, przegląd), właściwe ograniczenia i ewentualnie symulacja z losowym opóźnieniem synchronizatora.
- **Temat:** [15.07](../modules/15-zegary-reset-cdc/15.07-ograniczenia-i-weryfikacja-cdc.md)

## Architektura i synteza

### 23. Czy FPGA wykonuje kod równolegle, jak procesor z wieloma rdzeniami?

- **Częsta błędna odpowiedź:** „Tak, każdy proces to osobny wątek.”
- **Jak jest naprawdę:** FPGA nie wykonuje kodu. Kod HDL opisuje **układ**: każdy proces to kawałek sprzętu istniejący cały czas, a „wykonanie” to propagacja sygnałów między zboczami zegara. Pytanie sprawdza, czy kandydat myśli schematem, a nie programem.
- **Temat:** [07.01](../modules/07-kodowanie-pod-synteze/07.01-myslenie-sprzetowe-kod-hdl-to-schemat-nie.md)

### 24. Ile bitów konfiguracji ma LUT o k wejściach i ile LUT4 zajmie dowolna funkcja 6 zmiennych?

- **Częsta błędna odpowiedź:** „k bitów” albo „dwa LUT4, bo 4 + 2 wejścia”.
- **Jak jest naprawdę:** LUT to pamięć 2^k bitów — LUT4 ma 16, LUT6 — 64, czyli cztery razy więcej, a nie półtora. Dowolna funkcja 6 zmiennych w LUT4 to rozkład Shannona: 4 LUT4 na podfunkcje czterech zmiennych i multiplekser 4:1, który sam ma 6 wejść i zajmuje 3 LUT4 — razem 7 (w układzie z LUT6 jeden). Konkretna funkcja często upraszcza się do mniejszej liczby.
- **Temat:** [02.02](../modules/02-architektura-fpga/02.02-lut-przerzutnik-i-blok-logiczny-le-alm-clb-slice.md)

### 25. Czy mnożenie przez stałą zawsze zajmie blok DSP?

- **Częsta błędna odpowiedź:** „Tak, każde `*` to mnożarka.”
- **Jak jest naprawdę:** mnożenie przez potęgę dwójki to przesunięcie (zero logiki), przez inną stałą — kilka sum przesunięć (np. ×10 = ×8 + ×2), a syntezator sam wybiera między logiką a blokiem DSP. Dzielenie przez stałą też da się zamienić na mnożenie przez odwrotność; dzielenie przez zmienną — nie.
- **Temat:** [07.07](../modules/07-kodowanie-pod-synteze/07.07-wnioskowanie-mnozarek-i-blokow-dsp.md), [19.02](../modules/19-arytmetyka/19.02-mnozenie-i-bloki-dsp-potokowanie.md)

### 26. Pamięć z odczytem kombinacyjnym — trafi do bloku RAM?

- **Częsta błędna odpowiedź:** „Tak, każda tablica to blok RAM.”
- **Jak jest naprawdę:** bloki RAM (M9K, BRAM) mają **odczyt synchroniczny**. Odczyt kombinacyjny wymusza pamięć rozproszoną w LUT-ach, a w MAX 10 (bez LUTRAM) — przerzutniki i multipleksery, czyli tysiące elementów. Odczyt w takcie po adresie to podstawowy wzorzec wnioskowania RAM.
- **Temat:** [07.06](../modules/07-kodowanie-pod-synteze/07.06-wnioskowanie-pamieci-ram-i-rom.md), [18.01](../modules/18-pamieci/18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md)

### 27. Dopiszesz reset, który zeruje całą pamięć?

- **Częsta błędna odpowiedź:** „Tak, żeby zawartość była znana.”
- **Jak jest naprawdę:** bloki pamięci nie mają resetu zawartości — opis, który zeruje tablicę w pętli, zostanie zbudowany z przerzutników. Zawartość początkowa pochodzi z pliku inicjalizacji (`.mif`, `.hex`), a „wyczyszczenie” w czasie pracy to automat zapisujący zera adres po adresie (albo bit ważności przy każdym słowie).
- **Temat:** [07.06](../modules/07-kodowanie-pod-synteze/07.06-wnioskowanie-pamieci-ram-i-rom.md)

## Weryfikacja

### 28. Masz 100 % pokrycia kodu. Układ jest zweryfikowany?

- **Częsta błędna odpowiedź:** „Tak, każda linia została wykonana.”
- **Jak jest naprawdę:** pokrycie kodu mówi, co się **wykonało**, a nie co zostało **sprawdzone** ani jakie sytuacje wystąpiły (np. pełna kolejka z jednoczesnym zapisem i odczytem). Potrzebne są: pokrycie funkcjonalne według planu weryfikacji, model referencyjny i sprawdzenia (scoreboard, asercje).
- **Temat:** [10.07](../modules/10-weryfikacja-systemverilog/10.07-plan-weryfikacji-i-pokrycie-kodu.md), [10.03](../modules/10-weryfikacja-systemverilog/10.03-pokrycie-funkcjonalne-covergroup-coverpoint.md)

### 29. Testbench przechodzi w jednym symulatorze, a w innym nie. Wina symulatora?

- **Częsta błędna odpowiedź:** „Tak, jeden z nich ma błąd.”
- **Jak jest naprawdę:** prawie zawsze to **wyścig** w testbenchu: pobudzenia zmieniane na tym samym zboczu, na którym układ je próbkuje, albo blokujące przypisania między procesami. Kolejność zdarzeń w jednym kroku czasu jest niezdefiniowana. Pobudzenia na zboczu opadającym albo przypisaniami nieblokującymi, sprawdzenia w ustalonym miejscu.
- **Temat:** [09.01](../modules/09-symulacja-i-testbench/09.01-jak-dziala-symulator-zdarzenia-delta-cykle.md), [09.02](../modules/09-symulacja-i-testbench/09.02-pierwszy-testbench-zegar-reset-i-pobudzenia.md)

### 30. Symulacja przechodzi, więc na płytce zadziała?

- **Częsta błędna odpowiedź:** „Tak, jeśli testy są dobre.”
- **Jak jest naprawdę:** symulacja RTL nie widzi: naruszeń czasu (STA), CDC, różnic między symulacją a syntezą (lista wrażliwości, `x`, inicjalizacja), błędnych przypisań pinów i standardów I/O, zachowania zewnętrznych układów. Dlatego STA bez naruszeń, przegląd ostrzeżeń syntezy, symulacja po syntezie w razie wątpliwości i analizator logiczny na płytce.
- **Temat:** [17.05](../modules/17-debug-na-sprzecie/17.05-dziala-w-symulacji-nie-dziala-na-plytce-typowe.md)

### 31. Asercje w kodzie RTL spowolnią układ?

- **Częsta błędna odpowiedź:** „Tak, dodają logikę.”
- **Jak jest naprawdę:** asercje są dla symulatora i narzędzi formalnych — synteza je pomija. Kosztują tylko czas symulacji, a wykrywają błąd w miejscu, gdzie powstał, zamiast setki taktów później na wyjściu.
- **Temat:** [06.06](../modules/06-systemverilog-rtl/06.06-asercje-natychmiastowe-w-kodzie-rtl.md), [10.04](../modules/10-weryfikacja-systemverilog/10.04-asercje-sva-sekwencje-i-wlasciwosci.md)

### 32. Weryfikacja formalna przeszła. Symulacja niepotrzebna?

- **Częsta błędna odpowiedź:** „Tak, dowód obejmuje wszystkie przypadki.”
- **Jak jest naprawdę:** dowód jest tak dobry jak właściwości: BMC sprawdza tylko ograniczoną liczbę taktów, indukcja wymaga niezmienników, a zbyt mocne `assume` potrafią wykluczyć właśnie te wejścia, które psują układ (warto mieć `cover`, który pokazuje, że ciekawe stany są osiągalne). Formalna i symulacja uzupełniają się.
- **Temat:** [13.01](../modules/13-weryfikacja-formalna/13.01-dowod-zamiast-symulacji-bmc-indukcja-i-cover.md), [13.03](../modules/13-weryfikacja-formalna/13.03-pisanie-wlasciwosci-assume-assert-cover.md)

## Interfejsy i protokoły

### 33. W AXI — czy nadawca może czekać na `ready`, zanim ustawi `valid`?

- **Częsta błędna odpowiedź:** „Tak, po co wysyłać, gdy odbiorca nie jest gotowy.”
- **Jak jest naprawdę:** nie — `valid` nie może zależeć od `ready`, bo gdy odbiorca też czeka na `valid` (wolno mu), oba czekają w nieskończoność. Odbiorca może ustawić `ready` przed `valid` albo po nim. Przesłanie następuje w takcie, w którym oba są w stanie wysokim.
- **Temat:** [21.01](../modules/21-magistrale-on-chip/21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md), [08.05](../modules/08-automaty-stanow/08.05-handshake-valid-ready-i-przeplyw-danych.md)

### 34. Nadawca ustawił `valid`, a `ready` = 0. Może zmienić dane albo cofnąć `valid`?

- **Częsta błędna odpowiedź:** „Tak, dopóki nie było przesłania.”
- **Jak jest naprawdę:** nie — w AXI i Avalon-ST raz wystawione `valid` i dane muszą trwać bez zmian do przesłania. Odbiorca może więc spokojnie spojrzeć na dane takt później. Typowy błąd w skid bufferach i FIFO na wyjściu.
- **Temat:** [21.01](../modules/21-magistrale-on-chip/21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md)

### 35. Jak master I2C wystawia na SDA stan wysoki?

- **Częsta błędna odpowiedź:** „Ustawia wyjście na 1.”
- **Jak jest naprawdę:** linie I2C są typu otwarty dren: układy tylko ściągają linię do zera, a stan wysoki daje rezystor podciągający. Master „wystawia 1” przez zwolnienie linii (stan wysokiej impedancji). Dzięki temu działa arbitraż kilku masterów i rozciąganie zegara przez slave'a, który trzyma SCL w stanie niskim.
- **Temat:** [20.03](../modules/20-interfejsy-szeregowe/20.03-i2c-master-open-drain-i-rozciaganie-zegara.md)

### 36. Odbiornik UART próbkuje każdy bit na jego zboczu?

- **Częsta błędna odpowiedź:** „Tak, jak przy zegarze.”
- **Jak jest naprawdę:** UART nie przesyła zegara. Odbiornik wykrywa zbocze bitu startu, odlicza pół bitu (zwykle z nadpróbkowaniem 16×) i próbkuje **środki** bitów. Dzięki temu toleruje różnicę zegarów nadajnika i odbiornika rzędu kilku procent — błąd narasta przez 10 bitów ramki.
- **Temat:** [20.01](../modules/20-interfejsy-szeregowe/20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md)
