# Ściąga — 27 — Procesory w FPGA i systemy SoC

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [27.01 — Procesor w FPGA: miękki czy twardy](27.01-procesor-w-fpga-miekki-czy-twardy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Czas = instrukcje × CPI × okres zegara | porównanie procesorów |
| Miękki: zegar kilkadziesiąt–kilkaset MHz, od kilkuset LUT; twardy: GHz, 0 LUT, droższy układ | wybór |
| Linux wymaga MMU i pamięci zewnętrznej (DDR/SDRAM); bez MMU — bare metal albo RTOS | system operacyjny |
| RV32I: 40 instrukcji bazowych; M, A, F/D, C, Zicsr — rozszerzenia | RISC-V |
| Nios II → Nios V (RISC-V); MicroBlaze → także MicroBlaze V | narzędzia producentów |
| Procesor do sterowania, logika do przepustowości; dane — DMA, nie pętla w C | podział pracy |
| Automat, gdy sekwencja stała; procesor, gdy rośnie liczba stanów i parametrów | prostota |

## [27.02 — Nios V (RISC-V) w Platform Designer na DECA](27.02-nios-v-risc-v-w-platform-designer-na-deca.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Nios V/c — najmniejszy, bez przerwań; /m — RV32I + Zicsr, debug, timer; /g — RV32IMF, pamięci podręczne | wybór wariantu |
| `instruction_manager` → pamięć programu i `dm_agent`; `data_manager` → wszystko | połączenia |
| Reset Agent = pamięć z programem; moduł debugowania pozwala ładować program przez JTAG | uruchamianie |
| System w skrypcie (`qsys-script`), nie tylko w `.qsys` | kontrola wersji |
| `.sopcinfo` → BSP → `system.h` (adresy `*_BASE`, przerwania `*_IRQ`) | oprogramowanie |
| Przerwanie poziomem: procedura kasuje źródło przed wyjściem | ISR |
| Dostęp do rejestrów: `volatile` albo IORD/IOWR (obejście pamięci podręcznej w /g) | sterowniki |
| Program w RAM ginie po wyłączeniu: inicjalizacja pamięci `.hex` albo start z UFM | praca samodzielna |

## [27.03 — Własny peryferial z rejestrami i sterownik w C](27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Flagi zdarzeń W1C; ustawienie wygrywa z kasowaniem w tym samym takcie | rejestry statusu |
| Odczyt bez efektów ubocznych (poza FIFO) | debugowanie, podgląd |
| Rejestry cienia: nowe parametry od początku okresu/ramki | zmiana w trakcie pracy |
| Zezwolenie na przerwanie oddzielnie od flagi; irq = flaga & zezwolenie | przerwania |
| Własności interfejsu w `_hw.tcl` (readLatency, adresowanie) = zachowanie RTL | komponent |
| `volatile` dla rejestrów sprzętu; bariera/IORD-IOWR przy pamięci podręcznej i buforach zapisu | sterownik |
| Sterownik: funkcje według zamiarów, stałe pól, adres bazowy jako parametr | przenośność |

## [27.04 — Otwarte rdzenie RISC-V: PicoRV32, VexRiscv, NEORV32 i LiteX](27.04-otwarte-rdzenie-risc-v-picorv32-vexriscv.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| PicoRV32: mały, wielocyklowy (CPI ok. 4), interfejs z `mem_ready`; VexRiscv: potok z wtyczkami, Linux z MMU | wybór rdzenia |
| NEORV32: mikrokontroler z peryferiami i bootloaderem w VHDL, bez MMU | szybki start |
| SERV: bitowo-szeregowy, najmniejszy, ok. 32+ taktów na instrukcję | minimum zasobów |
| `-march` musi odpowiadać rozszerzeniom rdzenia (rv32i ≠ rv32im) | kompilacja |
| Linux wymaga MMU (Sv32), trybu nadzorcy i pamięci rzędu MB | wybór rdzenia |
| Weryfikacja: riscv-arch-test + RISCOF, porównanie śladu z ISS, riscv-formal (RVFI), riscv-dv | zmiany w rdzeniu |
| LiteX: `--cpu-type`, cele płytek (`terasic_deca`), BIOS, `litex_term` | szybki SoC |

## [27.05 — Układy SoC z twardym procesorem: Zynq, Cyclone V SoC, Agilex](27.05-uklady-soc-z-twardym-procesorem-zynq-cyclone-v.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Rejestry przez GP (AXI4-Lite, 32 b), dane przez HP (64 b, DMA), koherencja przez ACP/HPC | Zynq |
| Cyclone V: lekki most (rejestry, 32 b), mosty HPS↔FPGA (do 128 b), porty FPGA→SDRAM | SoC Altery |
| DMA + pamięć podręczna: flush przed DMA z pamięci, invalidate po DMA do pamięci | spójność danych |
| Boot: BootROM → FSBL/preloader → U-Boot → Linux; bitstream przez FSBL albo FPGA Manager | uruchamianie |
| Zegary dla PL z PS (FCLK) albo własne PLL; reset logiki z PS | integracja |
| Peryferia PS na piny przez MIO (stałe) albo EMIO (przez logikę) | piny |
| Zynq US+: APU (A53) do Linuksa, RPU (R5F) do czasu rzeczywistego | podział zadań |

## [27.06 — Linux na FPGA i podział sprzęt–oprogramowanie](27.06-linux-na-fpga-i-podzial-sprzetoprogramowanie.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Blok w logice = węzeł drzewa urządzeń: `compatible`, `reg`, `interrupts` | integracja z Linuksem |
| `/dev/mem` — test; UIO — prosty sterownik w przestrzeni użytkownika z przerwaniami; sterownik jądra — produkt | dostęp do rejestrów |
| Dane przez DMA i API DMA (flush/invalidate), nie przez rejestry | przepustowość |
| FPGA Manager + nakładka DT: bitstream i urządzenia razem, także rekonfiguracja częściowa | logika ładowana w działaniu |
| Linux na procesorze miękkim: MMU + pamięć zewnętrzna; bez MMU — HAL/RTOS | wybór systemu |
| S = 1 / ((1 − p) + p/k) — górna granica przyspieszenia | decyzja o akceleracji |
| Narzut wywołania + przerwania + koherencji rzędu µs — przetwarzaj wsadowo | małe porcje danych |

## [27.07 — Własny procesor RISC-V: od jednocyklowego do potokowego](27.07-wlasny-procesor-risc-v-od-jednocyklowego-do.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Czas = instrukcje × CPI × T; jednocyklowy CPI = 1 z długim T, potok CPI ≈ 1,2–1,5 z krótkim T | porównanie |
| Potok 5 stopni: IF, ID, EX, MEM, WB; rejestr między każdą parą | budowa |
| Przekazywanie MEM → EX (pierwszeństwo) i WB → EX; zapis rejestru widoczny w ID w tym samym takcie | hazardy danych |
| Load-use: 1 bąbelek (dane odczytu dopiero w WB) | odczyt + użycie |
| Skok rozstrzygany w EX: 2 takty kary; w ID: 1; predykcja i BTB zmniejszają średnią | hazardy sterowania |
| Pamięć blokowa: adres instrukcji = następny PC; dane odczytu w WB | FPGA |
| Takty = instrukcje + 2·skoki + load-use + napełnienie (tu 1894 + 682 + 162 + 4 = 2742) | analiza CPI |
| Wzorzec testu: ISS i ślad zapisów — niezależny od liczby taktów | weryfikacja rdzenia |
| Bez rozszerzenia M kompilator woła `__mulsi3` — dostarcz albo dołącz libgcc | C na RV32I |
