# Ściąga — 26 — Cyfrowe przetwarzanie sygnałów w FPGA

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [26.01 — Filtry FIR: struktury bezpośrednia, transponowana, symetryczna i systoliczna](26.01-filtry-fir-struktury-bezposrednia-transponowana.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| y[n] = Σ h[k]·x[n−k]; symetryczne h → liniowa faza, opóźnienie (N−1)/2 próbek | FIR |
| Transponowana: ścieżka = 1 mnożenie + 1 dodawanie, niezależnie od N; koszt — rozgałęzienie wejścia | wysoki zegar |
| Symetria: ⌈N/2⌉ mnożarek dzięki sumatorowi wstępnemu (wbudowany w DSP48, w MAX 10 — logika) | filtry z liniową fazą |
| Systoliczna: podwójna linia opóźniająca, łańcuch sum przez kaskadę bloków DSP, opóźnienie N taktów | długie filtry w DSP48 |
| Liczba mnożarek = ⌈N·fs / f_clk⌉ (⌈N/2⌉ przy symetrii) | dobór architektury |
| Akumulator ≥ bity iloczynu + ⌈log₂N⌉; zaokrąglaj i nasycaj raz, na końcu | stały przecinek |
| Okienkowany sinc: −6 dB przy fc; okno Hamminga — pasmo przejściowe ≈ 3,3·fs/N, listki ≈ −53 dB | projekt |
| Współczynniki Q1.15: wzmocnienie DC = Σh / 2¹⁵; zaokrąglanie każdego osobno przesuwa sumę o kilka LSB (tu 32 766) | kwantyzacja |

## [26.02 — Filtry IIR i stabilność w arytmetyce stałoprzecinkowej](26.02-filtry-iir-i-stabilnosc-w-arytmetyce.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Filtr wyższego rzędu = kaskada biquadów, nigdy jedna sekcja wysokiego rzędu | IIR w stałym przecinku |
| Stabilność biquadu: \|a2\| < 1 i \|a1\| < 1 + a2; promień biegunów r = √a2 | projekt, kwantyzacja |
| a1 dolnoprzepustowego blisko −2 → współczynniki Q2.x | format |
| Cykl graniczny przy zaokrąglaniu: rzędu ½/(1 − r) LSB (tu ok. 40, zmierzone 31) | bieguny blisko okręgu |
| Obcięcie w stronę zera (moduł malejący) usuwa cykle przy zerowym wejściu; floor daje składową −½ LSB | wybór kwantyzacji |
| W pętli IIR nasycenie, nie zawinięcie (oscylacje przepełnienia) | arytmetyka |
| Pętli nie da się spotokować bez zmiany filtru: przeplot K kanałów albo look-ahead | wysoki zegar |
| DF-II-T: stany pełnej precyzji, jedna kwantyzacja na wyjściu | sprzęt |

## [26.03 — Generatory NCO i DDS](26.03-generatory-nco-i-dds.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| f_out = ftw · f_we / 2ᴺ; rozdzielczość f_we / 2ᴺ (N = 32, 50 MHz → 11,6 mHz) | NCO |
| ftw = round(f_out · 2ᴺ / f_we) | ustawianie częstotliwości |
| SFDR ≈ 6,02 dB na bit fazy w tablicy (10 bitów → ~60 dB, zmierzone 57,7 dB) | obcięcie fazy |
| Ćwiartka sinusa: 2 bity ćwiartki + adres; odbicie adresu w ćw. 1, 3; znak w ćw. 2, 3 | kompresja tablicy |
| Tablica z przesunięciem o pół kroku — bez powtórzeń zera i szczytu | 2ᵏ słów na ćwiartkę |
| cos = sin(φ + 2ᴺ⁻²); sin i cos z jednego dwuportowego bloku pamięci | kwadratura |
| f_out ≲ 0,4 · f_we (Nyquist + filtr rekonstrukcyjny) | DDS |
| Sigma-delta 1. rzędu: gęstość jedynek = (x + 2ᴮ⁻¹)/2ᴮ; RC na pinie | tani przetwornik C/A |

## [26.04 — Decymacja i interpolacja: CIC i filtry wielofazowe](26.04-decymacja-i-interpolacja-cic-i-filtry.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Przed decymacją przez M stłumić wszystko powyżej f_we/(2M) — inaczej alias | decymacja |
| Wielofazowo: N mnożeń na wynik = N/M na próbkę wejściową; interpolacja — zera nie trafiają do mnożarki | filtry wieloszybkościowe |
| CIC: wzmocnienie (RM)ᴺ, rejestry B_we + N·log₂(RM) bitów, zawinięcie dozwolone | CIC |
| CIC: zera przy k·f_we/R, opadanie sinc^N w paśmie → filtr kompensujący (CFIR) | projekt łańcucha |
| Łańcuch: CIC (duże R) → CFIR (↓2) → FIR (↓2); drogie filtry przy najniższym fs | DDC, ADC sigma-delta |
| Filtr półpasmowy: co drugi współczynnik zerowy, ok. N/4 mnożeń na wynik przy ↓2 | decymacja przez 2 |
| Interpolator CIC: grzebienie przy niskim fs, integratory przy wysokim | interpolacja |

## [26.05 — FFT w sprzęcie](26.05-fft-w-sprzecie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| DFT: N² mnożeń zespolonych; FFT radix-2: (N/2)·log₂N motyli (64 → 192, 1024 → 5120) | koszt |
| Motyl: t = W·b, a ± t; mnożenie zespolone = 4 rzeczywiste (albo 3 + 5 dodawań) | sprzęt |
| DIT w miejscu: wejście z odwróconymi bitami, wyjście naturalne (DIF — odwrotnie) | kolejność |
| Wzrost do log₂N bitów; skalowanie ½ na etap → wynik DFT/N; albo blokowy wykładnik | stały przecinek |
| Współczynniki Q1.15: maksimum 32 767 (+1,0 się nie mieści) | tablica obrotów |
| Iteracyjna: 1 motyl, przepustowość ramka/(N/2·log₂N) taktów; potokowa: 1 próbka/takt, log₂N motyli | wybór architektury |
| Motyl na takt wymaga 2 odczytów + 2 zapisów — dwa banki pamięci według parzystości adresu | pamięć |
| Niecałkowita liczba okresów w bloku → przeciek; okno zmniejsza listki, poszerza prążek | analiza widma |

## [26.06 — Przetwarzanie I/Q i radio programowalne](26.06-przetwarzanie-i-q-i-radio-programowalne.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| I = x·cos(2πfc·n), Q = −x·sin(2πfc·n); widmo przesunięte o −fc, amplituda A/2 | przemiana w dół |
| Para I/Q rozróżnia +f i −f; jedna gałąź rzeczywista — nie | sygnał zespolony |
| DDC = NCO + 2 mnożarki + decymacja (CIC → CFIR → FIR) w każdej gałęzi | odbiornik cyfrowy |
| Wyrównaj opóźnienie próbki i NCO (tu 2 takty) | mieszanie |
| Obraz f + fc usuwa filtr decymacyjny; jego tłumienie w paśmie obrazu = tłumienie obrazu | projekt filtrów |
| Zero-IF: niezrównoważenie I/Q → obraz przy −f (25–40 dB bez korekcji), składowa stała | odbiornik analogowy I/Q |
| Próbkowanie pasmowe: sygnał w strefie k aliasuje do pierwszej — filtr pasmowy przed ADC | IF sampling |
| MAX 10: ADC 12 bitów, ≤ 1 MSPS | eksperymenty na DECA |

## [26.07 — Od modelu w Pythonie do RTL — weryfikacja bit w bit](26.07-od-modelu-w-pythonie-do-rtl-weryfikacja-bit-w.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Wzorzec testu = model całkowitoliczbowy z tą samą kwantyzacją, nie model zmiennoprzecinkowy z tolerancją | weryfikacja DSP |
| Jedno źródło: współczynniki, tablice i wektory generowane z modelu; CI sprawdza zgodność | utrzymanie |
| Python: `>>` = floor, `round()` = do parzystej, `int()` = w stronę zera; liczby bez szerokości → jawne zawinięcie | model |
| Verilog: `>>>` arytmetyczne tylko na `signed`; wycinek wektora jest bez znaku | RTL |
| Porównanie k-tego wyniku z k-tą wartością (flaga ważności), opóźnienie mierzone osobno | testbench |
| Własny generator pseudolosowy i jawne zaokrąglenia → wektory identyczne wszędzie | determinizm |
| Miary jakości (charakterystyka, SFDR, cykle graniczne) liczone na modelu bit w bit | decyzje o bitach |
