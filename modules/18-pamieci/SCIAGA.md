# Ściąga — 18 — Pamięci w FPGA

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [18.01 — Bloki pamięci: tryby jedno- i dwuportowe, odczyt podczas zapisu](18.01-bloki-pamieci-tryby-jedno-i-dwuportowe-odczyt.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Blok RAM: odczyt synchroniczny, ≤ 2 porty, bez resetu zawartości | wnioskowanie pamięci |
| M9K = 9216 bitów; 8K×1 … 256×36; 10M50: 182 bloki (1638 kbit) | MAX 10 |
| READ_FIRST: stara dana; WRITE_FIRST: nowa; NO_CHANGE: wyjście bez zmian | ten sam port |
| Dwa porty, jeden zegar: old data / don't care; dwa zegary: nieokreślone | porty mieszane |
| Przy dwóch zegarach protokół musi wykluczyć odczyt zapisywanego adresu | CDC przez pamięć |
| Odczyt asynchroniczny w MAX 10 → rejestry (brak pamięci rozproszonej) | MAX 10 |
| Rejestr wyjściowy bloku: +1 takt latencji, wyższa częstotliwość | szybkie ścieżki |

## [18.02 — ROM i inicjalizacja pamięci z pliku (.mif, .hex, .mem)](18.02-rom-i-inicjalizacja-pamieci-z-pliku-mif-hex-mem.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `initial $readmemh(PLIK, mem)` — przenośne w symulacji i syntezie | Verilog/SV |
| Ścieżka pliku względem katalogu roboczego narzędzia | wszystkie narzędzia |
| VHDL: textio w funkcji (symulacja, Vivado) + `ram_init_file` z `.mif` (Quartus) | VHDL |
| `.hex` dla `$readmemh` ≠ Intel HEX z rekordami `:` | formaty |
| Jeden skrypt generuje wszystkie formaty z jednego źródła | utrzymanie |
| Mała ROM może trafić do LUT; `rom_style`/`romstyle` wymusza blok | wnioskowanie |
| Zawartość ładowana tylko przy konfiguracji, reset jej nie przywraca | RAM z inicjalizacją |

## [18.03 — Synchroniczna kolejka FIFO i flagi](18.03-synchroniczna-kolejka-fifo-i-flagi.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Jedna domena: licznik słów (AW + 1 bitów) zamiast porównania wskaźników | FIFO synchroniczne |
| Zapis przy full i odczyt przy empty ignorowane w kolejce | ochrona |
| Standard: dana takt po `rd_en`; FWFT: dana czeka, `rd_en` = potwierdzenie | wybór trybu |
| FWFT na bloku RAM: rejestr wyjściowy pamięci + flaga valid, pojemność 2^AW + 1 | implementacja |
| AF = głębokość − opóźnienie reakcji producenta (w słowach) | dobór flag |
| Flagi z licznika i porównań ze stałymi — krótkie ścieżki | timing |
| `valid = !empty`, `ready = rd_en` — FWFT jako interfejs strumieniowy | łączenie bloków |

## [18.04 — Bufory pierścieniowe, ping-pong i bufory linii](18.04-bufory-pierscieniowe-ping-pong-i-bufory-linii.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Pierścień 2^AW: adres próbki sprzed k taktów = wr_ptr − k (modulo za darmo) | historia, przedwyzwolenie |
| Linia opóźniająca D: zapis i odczyt tego samego adresu, odczyt przed zapisem | długie opóźnienia w RAM |
| Ping-pong: 2 × blok pamięci, opóźnienie 1 blok, dowolna kolejność w bloku | FFT, przestawianie |
| Zamiana banków: zapis pełny ∧ odbiorca wolny; inaczej przeciwciśnienie | ping-pong |
| Bufor linii okna k × k: (k − 1) linii × W bitów × SZER | przetwarzanie obrazu |
| 640 × 16 bitów = 10 240 b > 9216 b jednego M9K | dobór pamięci |

## [18.05 — Pamięć flash użytkownika w MAX 10 (UFM)](18.05-pamiec-flash-uzytkownika-w-max-10-ufm.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| 10M50: UFM1 + UFM0 = 8 stron × 64 kbit = 64 KB (więcej zależnie od trybu) | DECA |
| Strona — najmniejsza kasowalna jednostka; kasowanie → same 1 | flash |
| Zapis zmienia tylko 1 → 0 (wynik = AND) | flash |
| 10 000 cykli, 20 lat przechowywania w 85 °C | projektowanie zapisu |
| Kasowanie strony do 350 ms | budżet czasu |
| Status [1:0] busy, [3] ws, [4] es; kontrolny [19:0] pe, [22:20] se, [27:23] wp | rdzeń On-Chip Flash |
| Zdejmij ochronę → operacja → busy = 00 → sprawdź ws/es → przywróć ochronę | sekwencja |

## [18.06 — ECC i ochrona danych w pamięci](18.06-ecc-i-ochrona-danych-w-pamieci.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Hamming: 2^r ≥ k + r + 1; SECDED: + 1 bit parzystości ogólnej | dobór kodu |
| 32 bity danych → 39 bitów, 64 → 72 | typowe szerokości |
| Syndrom = numer błędnej pozycji (XOR numerów pozycji z jedynką) | dekodowanie |
| Parzystość 1 → pojedynczy (popraw); syndrom ≠ 0 i parzystość 0 → podwójny | SECDED |
| Czyszczenie pamięci zanim w słowie nagromadzą się dwa błędy | długa praca, SEU |
| Liczniki błędów pojedynczych i wstrzykiwanie błędów do testów | system z ECC |
| M9K: brak sprzętowego ECC, bity ×9 dostępne na kontrolę | MAX 10 |
