# Rozmowa kwalifikacyjna na stanowisko FPGA

[← README](../README.md)

> **Status:** ✅ pełny

Ten katalog zbiera z całej bazy to, o co pytają na rozmowach technicznych na stanowiska: **FPGA Design Engineer**, **RTL Design Engineer**, **Design Verification Engineer** i **FPGA Engineer** w firmach z branży telekomunikacyjnej, motoryzacyjnej, lotniczej, obronnej, medycznej, pomiarowej i finansowej (handel wysokich częstotliwości).

## Zawartość

| Plik | Co zawiera |
|------|------------|
| [pytania.md](pytania.md) | Pytania ze wszystkich modułów z wzorcowymi odpowiedziami, ułożone według modułów (ok. 600, zbierane automatycznie z tematów) |
| [zadania-projektowe.md](zadania-projektowe.md) | 12 zadań „napisz na tablicy”: od detektora zbocza do slave'a AXI4-Lite i filtra FIR — z rozwiązaniem w trzech językach i testbenchami |
| [pulapki.md](pulapki.md) | 36 pytań podchwytliwych: częsta błędna odpowiedź i jak jest naprawdę |
| [hdl/](hdl/) | Kod zadań projektowych: `vhdl/`, `verilog/`, `sv/` — testowany w CI razem z modułami |

## Jak wygląda rekrutacja

Szczegóły zależą od firmy, ale większość procesów składa się z tych etapów:

1. **Rozmowa wstępna** (rekruter albo kierownik zespołu, 20–45 min) — doświadczenie, projekty, motywacja, oczekiwania. Pytania techniczne ogólne: „jaki układ i jakie narzędzia”, „co było najtrudniejsze w projekcie”.
2. **Test techniczny** — test zamknięty (logika cyfrowa, czas, CDC, język HDL) albo zadanie domowe: moduł z testbenchem w kilka dni. Przy zadaniu domowym oceniana jest też jakość: struktura, nazwy, testbench samosprawdzający, README z opisem decyzji.
3. **Rozmowa techniczna** (1–3 godziny, czasem kilka rozmów z różnymi osobami) — pytania z logiki cyfrowej, czasu i CDC, kodowanie na tablicy lub we współdzielonym edytorze, analiza przebiegów lub schematu („co tu jest nie tak?”), szczegółowe omówienie własnego projektu.
4. **Rozmowa końcowa** — zespół, sposób pracy, oczekiwania finansowe.

Na stanowiskach weryfikacyjnych w etapie 3 dochodzi SystemVerilog obiektowy, UVM, asercje i pokrycie; w firmach z HFT — opóźnienia liczone w taktach, Ethernet 10G/25G i wiedza o sieciach; w lotnictwie i obronności — procesy (DO-254), dokumentacja i niezawodność (moduł 29).

## Plan przygotowań

Dla osoby, która przeszła bazę, na 2–3 tygodnie przed rozmowami:

| Tydzień | Co | Materiał |
|---|---|---|
| 1 | Powtórka podstaw: liczby, układy kombinacyjne, przerzutniki, setup/hold, automaty | ściągi modułów [01](../modules/01-logika-cyfrowa/SCIAGA.md), [05](../modules/05-verilog/SCIAGA.md), [07](../modules/07-kodowanie-pod-synteze/SCIAGA.md), [08](../modules/08-automaty-stanow/SCIAGA.md), [14](../modules/14-analiza-czasowa/SCIAGA.md), pytania z tych modułów |
| 1 | Pułapki — odpowiedzi na głos z uzasadnieniem | [pulapki.md](pulapki.md) |
| 2 | Zadania projektowe na kartce, po jednym–dwa dziennie, potem porównanie i testbench | [zadania-projektowe.md](zadania-projektowe.md) |
| 2 | CDC i czas: rachunek zapasu, synchronizatory, FIFO asynchroniczne, ograniczenia | moduły [14](../modules/14-analiza-czasowa/README.md), [15](../modules/15-zegary-reset-cdc/README.md) |
| 3 | Własne projekty: opowieść 5-minutowa i 30-minutowa, liczby, decyzje, błędy | [moduł 31](../modules/31-projekty-koncowe/README.md), niżej |
| 3 | Pytania z modułów pod profil stanowiska (np. 10–11 dla weryfikacji, 22 i 25 dla interfejsów, 26 dla DSP) | [pytania.md](pytania.md) |

## Tematy, które wracają najczęściej

Oznaczone 💼 w [mapie modułów](../README.md#mapa-modułów). Najważniejsze:

- przypisania blokujące i nieblokujące, zatrzaski, lista wrażliwości — [moduły 04–07](../modules/07-kodowanie-pod-synteze/README.md),
- automaty stanów — [moduł 08](../modules/08-automaty-stanow/README.md),
- setup, hold, zapas i maksymalna częstotliwość — [moduł 14](../modules/14-analiza-czasowa/README.md),
- metastabilność, synchronizatory, asynchroniczne FIFO — [moduł 15](../modules/15-zegary-reset-cdc/README.md),
- potokowanie i kompromis powierzchnia–szybkość — [moduł 16](../modules/16-wydajnosc-zasoby-moc/README.md),
- UART, SPI, I²C — [moduł 20](../modules/20-interfejsy-szeregowe/README.md),
- AXI — [moduł 21](../modules/21-magistrale-on-chip/README.md),
- SystemVerilog weryfikacyjny i UVM — [moduły 10–11](../modules/10-weryfikacja-systemverilog/README.md),
- własny projekt z portfolio — [moduł 31](../modules/31-projekty-koncowe/README.md).

## Jak opowiadać o własnym projekcie

Pytanie „opowiedz o projekcie, z którego jesteś dumny” pada prawie zawsze i często decyduje o wyniku. Dobra odpowiedź ma strukturę i liczby:

1. **Cel i ograniczenia** — co układ robi, na jakim układzie FPGA, przy jakim zegarze i przepustowości, w jakim czasie.
2. **Architektura** — schemat blokowy z pamięci: domeny zegarowe, magistrale, gdzie są bufory i dlaczego.
3. **Jedna trudna decyzja** — jakie były warianty, co wybrałeś i jaki był koszt (np. „buforuję całą ramkę Ethernet, bo DDR3 może się wstrzymać, a MII nie ma pauzy — 2 bloki M9K więcej”, [31.04](../modules/31-projekty-koncowe/31.04-projekt-4-system-z-nios-v-ddr3-i-strumieniem-udp.md)).
4. **Jeden błąd i jak go znalazłeś** — testbench, analizator logiczny, raport czasowy (np. odstęp 1987 zamiast 3000 taktów w [31.06](../modules/31-projekty-koncowe/31.06-projekt-6-wlasny-procesor-risc-v-z-peryferiami.md)).
5. **Weryfikacja i wyniki** — jak testowałeś, zasoby, zapas czasowy, co byś zrobił inaczej.

Przygotuj wersję 5-minutową i 30-minutową, a na pytania szczegółowe — schemat i przebieg czasowy, które umiesz narysować. Rozmówca będzie drążył w miejscu, które brzmi niepewnie, więc nie wspominaj o rzeczach, których nie potrafisz wyjaśnić.

## Na rozmowie

- **Zanim zaczniesz pisać kod, dopytaj** — szerokości, reset, zachowanie przy przepełnieniu, wymagany zegar. Każde zadanie w [zadaniach projektowych](zadania-projektowe.md) ma listę takich pytań.
- **Myśl na głos** — rozmówca ocenia sposób rozumowania bardziej niż bezbłędny kod.
- **Najpierw schemat i przebiegi, potem kod** — w HDL kod jest opisem schematu.
- **Powiedz, jak to przetestujesz** — nawet gdy nikt nie pyta: model referencyjny, przypadki brzegowe, pokrycie.
- **„Nie wiem, ale sprawdziłbym tak…”** jest lepsze niż zgadywanie; zgadywanie z pewnością siebie jest najgorsze.
- **Pytaj o pracę**: jaki układ i narzędzia, jak wygląda weryfikacja (symulacja, formalna, sprzętowa), jak długie są projekty, kto pisze testbenche, jak wygląda przegląd kodu, czy jest CI dla HDL.

## Źródła

- C. E. Cummings, publikacje SNUG (przypisania nieblokujące, CDC, FIFO asynchroniczne) — [sunburst-design.com](http://www.sunburst-design.com/papers/) — klasyka pytań rekrutacyjnych z RTL.
- Arm, *AMBA AXI and ACE Protocol Specification* (IHI 0022) — reguły handshake i zależności kanałów.
- Pytania i zadania w tym katalogu są zbudowane na tematach bazy; pełne wyjaśnienia są w modułach, do których prowadzą linki.
