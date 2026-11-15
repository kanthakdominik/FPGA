# Słowniczek

[← README](README.md)

Pojęcia z całej bazy, alfabetycznie. Termin angielski jest podany wtedy, gdy w branży używa się głównie jego. Słowniczek rośnie razem z modułami.

| Pojęcie | Znaczenie | Temat |
|---------|-----------|-------|
| **ALM** (*Adaptive Logic Module*) | Blok logiczny w większych układach Altery (Cyclone V, Arria, Stratix, Agilex); w MAX 10 jego odpowiednikiem jest prostszy **LE** | 02 |
| **AXI** (*Advanced eXtensible Interface*) | Rodzina magistral z ekosystemu ARM AMBA: AXI4 (z burstami), AXI4-Lite (rejestry), AXI4-Stream (strumienie) | 21 |
| **Bitstream** | Plik konfiguracyjny układu FPGA; w Quartusie `.sof` (do pamięci SRAM przez JTAG) i `.pof` (do pamięci flash) | 03 |
| **BRAM**, **M9K** | Blok pamięci RAM wbudowany w układ; w MAX 10 bloki M9K po 9 Kb | 18 |
| **CDC** (*Clock Domain Crossing*) | Przekazywanie sygnału między częściami układu taktowanymi różnymi zegarami | 15 |
| **Clock enable** | Sygnał zezwalający przerzutnikowi na zapis w danym takcie — poprawny sposób „spowolnienia” logiki zamiast dzielenia zegara | 07 |
| **Delta cykl** | Krok symulacji o zerowym czasie, w którym symulator propaguje zmiany sygnałów | 09 |
| **DSP (blok)** | Wbudowany sprzętowy mnożnik (często z sumatorem i rejestrami) | 02, 19 |
| **Fanout** | Liczba wejść sterowanych przez jedno wyjście | 16 |
| **FIFO** | Kolejka „pierwszy wszedł, pierwszy wyszedł”; synchroniczna (jeden zegar) albo asynchroniczna (dwa zegary) | 18, 15 |
| **Hold** | Minimalny czas, przez który dane muszą pozostać stabilne po zboczu zegara | 01, 14 |
| **IP (rdzeń IP)** | Gotowy blok funkcjonalny (np. kontroler pamięci, PLL) dostarczany przez producenta lub inną firmę | 30 |
| **Jitter** | Losowe odchylenie chwili zbocza zegara od położenia idealnego | 14 |
| **LE** (*Logic Element*) | Podstawowy blok logiczny MAX 10: 4-wejściowy LUT, przerzutnik i logika przeniesień | 02 |
| **Lint** | Statyczne sprawdzanie kodu pod kątem błędów i złego stylu bez uruchamiania symulacji | 07 |
| **LUT** (*Look-Up Table*) | Mała pamięć realizująca dowolną funkcję logiczną kilku zmiennych — podstawa logiki FPGA | 02 |
| **Metastabilność** | Stan przerzutnika, w którym wyjście przez nieokreślony czas nie jest ani 0, ani 1 — skutek naruszenia setup lub hold | 01, 15 |
| **MTBF** (*Mean Time Between Failures*) | Średni czas między awariami; w CDC miara skuteczności synchronizatora | 15 |
| **Netlista** | Opis układu jako zbioru elementów i połączeń — wynik syntezy | 03 |
| **One-hot** | Kodowanie stanów, w którym każdemu stanowi odpowiada jeden przerzutnik | 08 |
| **Ograniczenia** (*constraints*) | Opis wymagań dla narzędzia: piny, standardy I/O, zegary, opóźnienia (pliki QSF, SDC, XDC) | 03, 14 |
| **PLL** (*Phase-Locked Loop*) | Pętla fazowa — blok generujący zegary o innej częstotliwości i fazie niż zegar wejściowy | 02, 15 |
| **Potokowanie** (*pipelining*) | Dzielenie długiej ścieżki kombinacyjnej rejestrami, żeby zwiększyć częstotliwość kosztem opóźnienia | 16 |
| **RTL** (*Register Transfer Level*) | Poziom opisu układu jako rejestrów i logiki między nimi — poziom, na którym pisze się kod HDL | 07 |
| **Setup** | Minimalny czas, przez który dane muszą być stabilne przed zboczem zegara | 01, 14 |
| **Skew** | Różnica chwil nadejścia tego samego zbocza zegara do różnych przerzutników | 14 |
| **Slack** (zapas) | Różnica między czasem wymaganym a rzeczywistym na ścieżce; ujemny oznacza naruszenie | 14 |
| **STA** (*Static Timing Analysis*) | Sprawdzanie wszystkich ścieżek czasowych bez symulacji | 14 |
| **SVA** (*SystemVerilog Assertions*) | Język asercji opisujących zachowanie układu w czasie | 10, 13 |
| **Synteza** | Przekształcenie opisu HDL w netlistę elementów układu | 03 |
| **Testbench** | Kod symulacyjny, który pobudza badany układ i sprawdza jego odpowiedzi | 09 |
| **Timing closure** (zamykanie timingu) | Doprowadzenie projektu do stanu, w którym wszystkie ścieżki spełniają wymagania czasowe | 16 |
| **UVM** | Standardowa metodologia budowy środowisk weryfikacyjnych w SystemVerilogu (IEEE 1800.2) | 11 |
| **Zatrzask** (*latch*) | Element pamiętający sterowany poziomem, a nie zboczem; w FPGA zwykle niezamierzony efekt niepełnego opisu logiki kombinacyjnej | 01, 07 |
