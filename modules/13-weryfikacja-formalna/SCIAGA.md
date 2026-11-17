# Ściąga — 13 — Weryfikacja formalna

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [13.01 — Dowód zamiast symulacji: BMC, indukcja i cover](13.01-dowod-zamiast-symulacji-bmc-indukcja-i-cover.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| BMC PASS = brak błędu w *k* taktach od resetu, nic więcej | interpretacja wyniku `bmc` |
| Indukcja = baza (BMC *k*) + krok z **dowolnego** stanu | tryb `prove` |
| `UNKNOWN` przy `prove` = baza OK, krok indukcyjny nie — dodaj niezmiennik albo zwiększ *k* | CTI |
| Stan, który może „stać” (wstrzymanie, `en = 0`), wymaga niezmiennika — większe *k* nie pomoże | k-indukcja |
| Cover PASS = scenariusz osiągalny; FAIL = nieosiągalny w *k* | sprawdzanie założeń |
| Każda grupa asercji potrzebuje coverów — inaczej dowód może być pusty | zawsze |
| Bezpieczeństwo: kontrprzykład skończony; żywotność: nieskończony | rodzaj właściwości |
| Praktyczny zasięg: bloki do 10⁴–10⁵ przerzutników, BMC — dziesiątki taktów | dobór metody |

## [13.02 — SymbiYosys: pierwsze dowody](13.02-symbiyosys-pierwsze-dowody.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| `.sby` = `[tasks]`, `[options]`, `[engines]`, `[script]`, `[files]` | każdy projekt SymbiYosys |
| Jedno `zadanie:` na linię; `~zadanie:` = wszystkie oprócz | warianty w jednym pliku |
| Kody `sby`: 0 PASS, 2 FAIL, 4 UNKNOWN, 16 ERROR | skrypty i CI |
| `smtbmc yices` — domyślny; `abc pdr` — dowód bez ręcznych niezmienników | wybór silnika |
| `f_past_valid` przed każdym `$past` i asercją stanu | zawsze |
| Otwarty Yosys: asercje natychmiastowe + `$past`; sekwencje SVA — tylko z Verific | pisanie właściwości |
| VHDL: PSL przez GHDL (`-fpsl`, `plugin -i ghdl`) | właściwości w VHDL |
| Oczekiwane FAIL/UNKNOWN sprawdza się tak samo jak PASS | regresja formalna |

## [13.03 — Pisanie właściwości: assume, assert, cover](13.03-pisanie-wlasciwosci-assume-assert-cover.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Założenia na wejściach, asercje na wyjściach i stanie | podział właściwości |
| Każde założenie musi wynikać ze specyfikacji interfejsu | przegląd założeń |
| Reguła źródła: wstrzymane `valid` + dane stabilne do przyjęcia | interfejsy valid/ready |
| Model odniesienia napisany inaczej niż układ | asercje funkcji |
| Cover dla każdej grupy asercji; FAIL coveru = podejrzane założenia | zawsze |
| Sprzeczne założenia = wszystko „udowodnione”, wszystkie covery FAIL | diagnoza |
| `anyconst` — dowolna stała; `anyseq` — dowolna w każdym takcie | wartości symboliczne |
| Ta sama właściwość: assume u odbiorcy, assert u nadawcy | assume-guarantee |

## [13.04 — Formalna weryfikacja FIFO i interfejsów z handshakiem](13.04-formalna-weryfikacja-fifo-i-interfejsow-z.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Wskaźniki o 1 bit szersze niż adres: równe = pusta, różny tylko MSB = pełna | FIFO o głębokości 2ⁿ |
| `count = wr_ptr − rd_ptr`, zakres 0…2ⁿ | FIFO |
| Integralność danych: śledź 1 (lub 2) dowolne elementy, nie całą zawartość | kolejki, bufory |
| Niezmienniki: granice licznika, element między wskaźnikami, komórka nienadpisana | indukcja dla FIFO |
| Właściwości z sygnałami wewnętrznymi — w RTL pod `` `ifdef FORMAL `` albo przez `bind` | dostęp do stanu |
| valid trzyma się do przyjęcia, dane stabilne, valid nie czeka na ready | handshake AXI i pokrewne |
| Covery zerowane resetem — inaczej solver „skraca drogę” przez reset | cover sekwencji zdarzeń |
| PDR bez niezmienników: wolniej (tu ×10), ale bez ręcznej pracy | wybór silnika |

## [13.05 — Sprawdzanie równoważności i metody formalne w przemyśle](13.05-sprawdzanie-rownowaznosci-i-metody-formalne-w.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Miter: te same wejścia, wyjście = „wyniki różne”; dowód: `trigger` nieosiągalny | każda równoważność |
| LEC dopasowuje rejestry i dowodzi logiki kombinacyjnej między nimi | RTL ↔ netlista |
| Retiming, zmiana kodowania FSM, bramkowanie zegara → sprawdzanie sekwencyjne | gdy dopasowanie zawodzi |
| Yosys: `equiv_make` → `equiv_simple` → `equiv_induct` → `equiv_status -assert` | otwarty LEC |
| LEC po każdej syntezie, DFT i ECO | przepływ ASIC (obowiązkowo), FPGA certyfikowane |
| FPV: Jasper, VC Formal, Questa Formal; LEC: Conformal, Formality | narzędzia przemysłowe |
| Aplikacje formalne: łączność, CSR, X-prop, CDC, bezpieczeństwo, UNR | weryfikacja SoC |
