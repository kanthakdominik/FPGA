# Ściąga — 15 — Zegary, reset i przejścia między domenami (CDC)

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [15.01 — Generowanie zegarów: PLL, clock enable i dlaczego nie bramkować zegara](15.01-generowanie-zegarow-pll-clock-enable-i-dlaczego.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Wolniejszy rytm = zezwolenie zegara, nie nowy zegar | zawsze, gdy się da |
| Zegary tylko z pinów zegarowych, PLL i bloków sterowania zegarem, sieciami globalnymi | FPGA |
| Logika za PLL w resecie, dopóki `locked = 0` | każde PLL |
| Zegary z jednego PLL — spokrewnione (STA); z różnych oscylatorów — asynchroniczne (CDC) | podział na domeny |
| Bramka AND na zegarze: dodatkowe zbocza, skew, problemy w STA | nigdy w FPGA |
| Wyłączanie zegara: ALTCLKCTRL `ena` (MAX 10), BUFGCE (AMD); w ASIC — komórka ICG | oszczędzanie energii |
| Liczba domen = liczba zegarów, które naprawdę muszą być różne | architektura |

## [15.02 — Metastabilność i MTBF — rachunek](15.02-metastabilnosc-i-mtbf-rachunek.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MTBF = exp(t_r/τ) / (T_w · f_clk · f_dane) | każdy synchronizator |
| t_r: wykładniczo, f: liniowo — czas ustalenia jest najważniejszy | projektowanie synchronizatora |
| Zero logiki między stopniami synchronizatora | zawsze |
| 2 przerzutniki standardowo, 3 przy wysokich f / długim życiu / wielu kopiach | dobór liczby stopni |
| Opóźnienie synchronizatora niepewne o ±1 takt | protokoły CDC |
| Symulacja RTL nie pokazuje metastabilności — błędy CDC wykrywa analiza strukturalna | weryfikacja |
| `ASYNC_REG` / `SYNCHRONIZER_IDENTIFICATION` na przerzutnikach synchronizatora | kodowanie |

## [15.03 — Synchronizatory jednobitowe i synchronizacja impulsów](15.03-synchronizatory-jednobitowe-i-synchronizacja.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Źródło z rejestru, zero logiki między stopniami, wyjście FF1 tylko do FF2 | każdy synchronizator |
| Poziom stabilny ≥ 1,5 okresu (3 zbocza) zegara docelowego | synchronizator poziomu |
| Opóźnienie 2–3 takty docelowe, niepewne o ±1 | protokoły |
| Impuls → przełącznik → 2FF → wykrycie zmiany | impulsy między domenami |
| Kolejny impuls dopiero po potwierdzeniu (busy) albo z gwarantowaną przerwą | przepustowość |
| Jeden bit na synchronizator; szyny — Gray, handshake, FIFO | sygnały wielobitowe |
| Gotowe makra: XPM_CDC (AMD), `altera_std_synchronizer`, `dcfifo` (Intel) | projekty produkcyjne |

## [15.04 — Przesyłanie słów: handshake, kod Graya i MCP](15.04-przesylanie-slow-handshake-kod-graya-i-mcp.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Szyny nie synchronizuje się bit po bicie (wyjątek: kod Graya) | każde słowo |
| MCP: dane stałe, synchronizowane tylko „ważne”; dane stabilne ≥ 2 takty odbiorcy przed zapisem | słowa rzadkie |
| Handshake dwufazowy: każda zmiana req = słowo; ready = (req == ack_src) | kontrola przepływu |
| gray = bin ^ (bin >> 1); bin[i] = XOR gray[W−1:i] | liczniki, wskaźniki |
| Gray: zmiana o ±1 na takt, rejestr przed synchronizatorem, rozrzut bitów < okres nadawcy | warunki poprawności |
| Odczyt Graya w odbiorniku: stara albo nowa wartość, monotonicznie | wskaźniki FIFO |
| Strumień danych — FIFO, nie handshake | przepustowość |

## [15.05 — Asynchroniczna kolejka FIFO](15.05-asynchroniczna-kolejka-fifo.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Wskaźniki AW+1 bitów; przez domeny tylko Gray z rejestru | asynchroniczne FIFO |
| Pusta: `rd_gray_n == wr_gray_sync` (w domenie odczytu) | flaga pusta |
| Pełna: `wr_gray_n == {~rd_sync[AW:AW−1], rd_sync[AW−2:0]}` (w domenie zapisu) | flaga pełna |
| Flagi pesymistyczne: ustawiane natychmiast, zdejmowane po 2–3 taktach | projektowanie przepływu |
| Głębokość ≥ paczka · (1 − f_rd/f_wr) + zapas na opóźnienie flag | dobór głębokości |
| Dane w pamięci nigdy nie przez synchronizator | architektura |
| Obie strony w resecie, zanim którakolwiek ruszy | reset |

## [15.06 — Strategie resetu: synchronizator resetu i RDC](15.06-strategie-resetu-synchronizator-resetu-i-rdc.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Reset tylko tam, gdzie potrzebny (sterowanie, flagi, wskaźniki), nie dla danych | każdy projekt |
| Ustawienie asynchroniczne, zdjęcie synchroniczne — synchronizator resetu w **każdej** domenie | reset asynchroniczny |
| Zdjęcie resetu sprawdzane jako recovery/removal | STA |
| `locked` PLL wchodzi do resetu domen taktowanych z PLL | PLL |
| Domeny zależne: kolejność zwalniania (producent przed konsumentem) | wiele domen |
| RDC: przerzutnik z resetem asynchronicznym R1 zasila przerzutnik bez R1 → izolacja albo wspólny reset | reset częściowy |
| Wejście resetu zewnętrznego do synchronizatora: `set_false_path` | SDC |

## [15.07 — Ograniczenia i weryfikacja CDC](15.07-ograniczenia-i-weryfikacja-cdc.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Każda para domen w raporcie przejść: ograniczona albo świadomie wyłączona | każdy projekt z wieloma zegarami |
| Pojedynczy bit przez synchronizator: `set_clock_groups -asynchronous` / false path | bity sterujące |
| Wskaźniki Graya, dane handshake/MCP: max delay bez zegarów + skew, nie sama grupa | magistrale przez domeny |
| `set_clock_groups`/`set_false_path` mają pierwszeństwo przed `set_max_delay` | Vivado, OpenSTA, SDC |
| Quartus: `set_net_delay`/`set_max_skew` działają też przy grupach | MAX 10, `dcfifo` |
| Opóźnienie bitu wskaźnika Graya < okres nadajnika | asynchroniczne FIFO |
| Synchronizatory oznaczone: `ASYNC_REG` (Vivado), `SYNCHRONIZER_IDENTIFICATION` (Quartus) | raport MTBF, rozmieszczenie |
| Analiza strukturalna sprawdza wzorce, nie protokół — protokół sprawdza test lub dowód | weryfikacja CDC |
