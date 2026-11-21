# Ściąga — 23 — Pamięci zewnętrzne

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [23.01 — SDRAM i DDR: jak działają, odświeżanie i opóźnienia](23.01-sdram-i-ddr-jak-dzialaja-odswiezanie-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Odświeżanie: 64 ms na wszystkie wiersze, REFRESH co tREFI = 7,8 µs, strata tRFC/tREFI ≈ 2–5 % | DDR3/DDR4 do 85 °C |
| Trafienie: CL; chybienie: tRCD + CL; konflikt: tRP + tRCD + CL (~40 ns) | opóźnienie dostępu |
| CL, tRCD, tRP ≈ 13–15 ns od lat — rośnie przepustowość, nie opóźnienie | generacje DDR |
| DDR3: 8 banków, prefetch 8n, BL8 = 4 takty; DDR4: 16 banków w 4 grupach | organizacja |
| Przepustowość szczytowa = szerokość × MT/s; efektywna 20–90 % zależnie od wzorca | planowanie systemu |
| Dane sekwencyjnie w wierszu, przeplot banków, grupowanie zapisów | dobre wykorzystanie |

## [23.02 — Kontroler DDR3 na MAX 10 (UniPHY)](23.02-kontroler-ddr3-na-max-10-uniphy.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Kontroler (kolejka, rozkazy, odświeżanie) + PHY (I/O, DQS, kalibracja) + PLL — jako IP producenta | każdy DDR w FPGA |
| MAX 10 DDR3: do ok. 300 MHz zegara pamięci, interfejs użytkownika half rate | DECA |
| ×16, DDR, half rate → 64 bity danych na takt zegara użytkownika | szerokość portu |
| Ruch dopiero po `local_init_done` i `local_cal_success` | integracja |
| Piny i standardy z generatora (`*_pin_assignments.tcl`), ograniczenia z `.sdc` IP, raport DDR w STA | implementacja |
| Logika na innym zegarze niż AFI — przejście CDC (FIFO, mostek) | domeny zegarowe |

## [23.03 — Pamięci QSPI flash i HyperRAM](23.03-pamieci-qspi-flash-i-hyperram.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Transakcja: rozkaz + adres (24/32 b) + puste + dane; notacja 1-1-1, 1-1-4, 1-4-4 | SPI/QSPI flash |
| Każdy zapis/kasowanie: WREN → rozkaz → odpytywanie WIP | flash |
| Programowanie 1 → 0, strona 256 B (zawijanie), kasowanie sektora 4 KB / bloku 64 KB | flash NOR |
| tPP ≈ 0,5–3 ms, tSE 4 KB ≈ 30–400 ms, ~100 000 cykli kasowania | planowanie zapisu |
| Quad wymaga bitu QE; pamięci > 16 MB — adres 4-bajtowy | konfiguracja |
| HyperRAM: 12 sygnałów, DDR ×8, RWDS, opóźnienie ×2 przy odświeżaniu, ~333 MB/s | tani RAM |

## [23.04 — Arbitraż dostępu do pamięci i DMA](23.04-arbitraz-dostepu-do-pamieci-i-dma.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Priorytet stały → możliwe zagłodzenie; round-robin → oczekiwanie ≤ N−1 transferów | wybór arbitrażu |
| `waitrequest` = 0 tylko dla mastera, którego transfer przyjęto | Avalon-MM z arbitrem |
| Odczyty potokowe: kolejka numerów masterów kieruje `readdatavalid` | wielu masterów, odpowiedzi w kolejności |
| DMA bez odczytów w toku: przepustowość 1/L przy opóźnieniu L | projekt DMA |
| Odczytów w locie ≤ wolne miejsce w buforze — odpowiedzi nie da się wstrzymać | Avalon-MM, AXI bez backpressure R |
| Arbitraż burstami przed kontrolerem DDR | wydajność pamięci |

## [23.05 — Karta microSD: tryb SPI i tryb SD](23.05-karta-microsd-tryb-spi-i-tryb-sd.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| ≥ 74 takty z CS = 1, SCLK 100–400 kHz do końca inicjalizacji, potem do 25 MHz | start karty |
| CMD0 → CMD8 (0x1AA) → CMD55+ACMD41 (HCS) do R1 = 0 → CMD58 (CCS) [→ CMD16] | inicjalizacja SPI |
| SDHC/SDXC: adres = numer bloku; SDSC: adres w bajtach | CMD17/CMD24 |
| Rozkaz 48 b z CRC7 (x⁷+x³+1); dane: token 0xFE + 512 B + CRC16 (CCITT) | ramki |
| ACMD41 do ~1 s, odczyt do ~100 ms, zapis do ~250 ms (zajętość) | limity czasu |
| Blok 0: MBR/sektor rozruchowy, sygnatura 0x55 0xAA w bajtach 510–511 | system plików |
