# Ściąga — 19 — Arytmetyka i liczby w sprzęcie

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [19.01 — Stałoprzecinkowe formaty Q: skalowanie, zaokrąglanie, nasycenie](19.01-staloprzecinkowe-formaty-q-skalowanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Qm.n: m + n bitów, zakres [−2^(m−1), 2^(m−1) − 2^−n], LSB = 2^−n | format Q (m z bitem znaku) |
| Qa.b × Qc.d = Q(a+c).(b+d); Q1.15 × Q1.15 = Q2.30 | mnożenie |
| Suma N składników: +⌈log₂N⌉ bitów części całkowitej | akumulatory |
| Obcięcie: obciążenie ≈ −½ LSB; zbieżne: 0 | wybór zaokrąglania |
| Przepełnienie: bity od znaku wyjścia w górę nie są kopiami znaku | detekcja |
| Pośrednie przepełnienia w sumie U2 się znoszą — nasycaj tylko wynik | akumulatory, filtry |
| Szum kwantyzacji LSB/√12; SQNR ≈ 6,02N + 1,76 dB | dobór liczby bitów |

## [19.02 — Mnożenie i bloki DSP — potokowanie](19.02-mnozenie-i-bloki-dsp-potokowanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10: bloki 18 × 18 albo 2 × 9 × 9; 10M50 — 144 (288) | DECA |
| 17 × 17 bez znaku = 18 × 18 ze znakiem; bez znaku: rozszerz o bit zerem | znak w bloku |
| 2H × 2H = 4 mnożenia (H+1) × (H+1): 34 × 34 → 4 bloki 18 × 18 | szerokie mnożenie |
| Rejestr za iloczynami częściowymi przed sumą — w eksperymencie +63 % f_max | potok szerokiej mnożarki |
| Rejestry wejściowe i wyjściowe — w bloku, bez kosztu; bez resetu | wnioskowanie |
| Zespolone: 3 mnożenia + 5 dodawań zamiast 4 + 2 | brak bloków DSP |
| Mnożenie przez stałą: przesunięcia i dodawania (CSD) | stałe współczynniki |

## [19.03 — Dzielenie i pierwiastek: algorytmy iteracyjne](19.03-dzielenie-i-pierwiastek-algorytmy-iteracyjne.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Dzielenie z odtwarzaniem: 1 bit / takt, sumator W+1 bitów, W taktów | iteracyjnie |
| Potok: W stopni, 3W² przerzutników, wynik w każdym takcie | duża przepustowość |
| Ze znakiem: dziel moduły; iloraz do zera, reszta ze znakiem dzielnej | C, Verilog, VHDL `rem` |
| x/0: iloraz = jedynki, reszta = x; min/−1 = min, reszta 0 (RISC-V) | specyfikacja |
| Pierwiastek: 2 bity x na krok, odjemnik 4p + 1, reszta = x − p² | pierwiastek całkowity |
| Newton–Raphson: bity odwrotności podwajają się w każdej iteracji | dzielenie mnożarkami |
| Dzielenie przez stałą = mnożenie przez odwrotność i przesunięcie | stały dzielnik |

## [19.04 — CORDIC](19.04-cordic.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Kąty atan(2⁻ⁱ): 45°, 26,57°, 14,04°, 7,13°…; suma 99,88° | zbieżność |
| K = Π√(1 + 2⁻²ⁱ) ≈ 1,64676; kompensacja: x₀ = A/K | sin/cos |
| ~1 bit na iterację; N ≈ W + 2, G ≈ log₂N bitów ochronnych | dobór parametrów |
| Obrót wstępny ±90° → cały okrąg | zakres |
| Kąt binarny: 2ᴬ = 360°, 90° = 2ᴬ⁻², zawijanie za darmo | reprezentacja kąta |
| Obrót: dᵢ = sign(z); wektorowanie: dᵢ = −sign(y) | tryby |
| Potok: N stopni po 3 sumatory, 0 mnożarek | koszt |

## [19.05 — Liczby zmiennoprzecinkowe w FPGA: IEEE 754 i rdzenie IP](19.05-liczby-zmiennoprzecinkowe-w-fpga-ieee-754-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| binary32: 1/8/23, obciążenie 127, ~7 cyfr, 1,2·10⁻³⁸…3,4·10³⁸ | float |
| bfloat16 = 16 starszych bitów binary32 (zakres float, 3 cyfry) | AI |
| e = 0: zero/zdenormalizowane; e = max: ∞ (f = 0) / NaN (f ≠ 0) | wartości specjalne |
| Do najbliższej, połówka do parzystej; guard + round + sticky | zaokrąglanie |
| Mnożenie: mantysy × (DSP), wykładniki +, normalizacja o 0/1 bit | mnożarka FP |
| Dodawanie: wyrównanie, przesuwnik, LZC, normalizacja — droższe od mnożenia | sumator FP |
| DAZ/FTZ — tańszy sprzęt, odstępstwo od IEEE 754, opisać w specyfikacji | FPGA, GPU |

## [19.06 — Tablice i aproksymacja funkcji](19.06-tablice-i-aproksymacja-funkcji.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Najpierw redukcja argumentu (symetrie, normalizacja do [1, 2)) | każda funkcja |
| Tablica 2^S słów: błąd ~ f′·h/2 | bez interpolacji |
| Interpolacja liniowa: błąd ~ f″·h²/8, ×¼ przy podwojeniu odcinków | 1 mnożarka |
| Minimax: połowa błędu cięciwy przy tych samych tablicach | dobór współczynników |
| sin, 16 b: 64 odcinki liniowo — 3,8 LSB; tablica 4096 słów — 13 LSB | rząd wielkości |
| Wielomian stopnia n schematem Hornera: n mnożeń, n dodawań | potok |
| 2–4 bity ochronne we współczynnikach i iloczynie | budżet błędu |
