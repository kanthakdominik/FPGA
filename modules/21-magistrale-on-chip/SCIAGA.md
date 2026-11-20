# Ściąga — 21 — Magistrale i interfejsy na chipie

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [21.01 — Strumienie z handshakiem: AXI4-Stream i Avalon-ST](21.01-strumienie-z-handshakiem-axi4-stream-i-avalon-st.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Transfer = TVALID ∧ TREADY przy zboczu zegara | każdy strumień |
| Nadajnik nie czeka na TREADY z TVALID; po ustawieniu TVALID trzyma je i dane do handshake'u | reguły AXI4-Stream |
| Bajt 7:0 jest pierwszy; TLAST — koniec pakietu; TKEEP = 0 — bajt pusty | pakiety |
| Avalon-ST: startofpacket/endofpacket/empty; readyLatency N — dane N taktów po ready | Intel |
| Rejestr na ready łamie protokół — rozcięcie ścieżki ready = bufor poślizgowy (2 rejestry) | długie potoki |
| Bufor poślizgowy: 1 słowo/takt, wszystkie wyjścia z przerzutników | *register slice* |

## [21.02 — Rejestry sterujące: AXI4-Lite i Avalon-MM](21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| AXI4-Lite: AW, W, B, AR, R — każdy z handshake'iem valid/ready | slave rejestrów |
| AW i W niezależne; BVALID dopiero po obu; RVALID po AR | zależności kanałów |
| OKAY 00, SLVERR 10, DECERR 11 | BRESP, RRESP |
| WSTRB / byteenable: bit n ↔ bajt n | zapis częściowy |
| Avalon-MM: transfer gdy read/write ∧ ¬waitrequest; readLatency stałe albo readdatavalid | slave Intel |
| Master Avalon — adresy bajtów, slave zwykle słów | Platform Designer |
| W1C: `(przer & ~kasuj) \| zdarz` — zdarzenie wygrywa | flagi przerwań |

## [21.03 — AXI4 i Avalon-MM z burstami](21.03-axi4-i-avalon-mm-z-burstami.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| AxLEN = takty − 1; INCR do 256, FIXED i WRAP do 16 (WRAP: 2, 4, 8, 16) | AXI4 |
| Bajtów na takt = 2^AxSIZE | AXI4 |
| WRAP: okno L·S wyrównane do swojego rozmiaru, start wyrównany do S | pamięć podręczna |
| Burst nie przekracza granicy 4 KB | każdy master AXI |
| Ten sam ID → ta sama kolejność; różne ID → dowolna | kolejność odpowiedzi |
| Avalon: adres i burstcount w pierwszym takcie; odczyt = jeden rozkaz + burstcount × readdatavalid | Avalon-MM |
| Przepustowość burstu: 1 słowo/takt po opóźnieniu startowym | wydajność |

## [21.04 — Wishbone i magistrale otwarte](21.04-wishbone-i-magistrale-otwarte.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Klasyczny: transfer = STB ∧ ACK; z rejestrowanym ACK 1 słowo / 2 takty | Wishbone klasyczny |
| Potokowy: żądanie przyjęte przy CYC ∧ STB ∧ ¬STALL; jedna odpowiedź na żądanie, w kolejności | Wishbone B4 |
| CYC = 0 przerywa cykl i unieważnia odpowiedzi w drodze | koniec cyklu |
| Slave klasyczny w potoku: STALL = ¬ACK | adapter |
| Dekoder bez slave'a pod adresem odpowiada ERR (jak DECERR) | interconnect |
| Mostek między magistralami = opóźnienie i często mniejsza przepustowość | system |

## [21.05 — Mapa rejestrów i generatory: SystemRDL, PeakRDL](21.05-mapa-rejestrow-i-generatory-systemrdl-peakrdl.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Mapa rejestrów ma jedno źródło; RTL, C, dokumentacja i model UVM są generowane | każdy projekt z oprogramowaniem |
| SystemRDL: addrmap → regfile → reg → field | struktura opisu |
| `sw`/`hw` — dostęp programowy i sprzętowy; `onwrite = woclr` — W1C; `intr` — bit lepki ustawiany przez sprzęt | właściwości pól |
| PeakRDL-regblock: logika rejestrów + wybierany interfejs CPU (AXI4-Lite, Avalon-MM, APB) | generowany slave |
| Wygenerowanego kodu nie edytuje się — zmienia się opis | przepływ pracy |
| Gdy kod jest ręczny, test porównuje go z opisem | okres przejściowy |

## [21.06 — Platform Designer i IP Integrator](21.06-platform-designer-i-ip-integrator.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Komponent = HDL + opis interfejsów (`_hw.tcl` / IP-XACT) z własnościami zgodnymi z RTL | własny blok w systemie |
| Interconnect generuje dekodery, arbitraż, adaptery szerokości/burstów i przejścia zegarowe | system |
| Conduit / external — sygnały wyprowadzone poza system | piny, logika użytkownika |
| JTAG to Avalon Master Bridge + System Console: `master_read_32`, `master_write_32` | uruchamianie bez procesora |
| W repozytorium skrypt Tcl systemu, nie wygenerowany `.qsys`/`.bd` i HDL | kontrola wersji |
| `.sopcinfo` / `.xsa` — mapa adresów dla oprogramowania | BSP i sterowniki |
