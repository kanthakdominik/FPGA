# Ściąga — 22 — Wejścia-wyjścia i szybkie interfejsy

[← moduł](README.md)

Reguły i liczby do zapamiętania ze wszystkich tematów modułu (generowane przez `tools/zbierz.py` z sekcji tematów).

## [22.01 — Standardy I/O, terminacja, siła sterowania i slew rate](22.01-standardy-i-o-terminacja-sila-sterowania-i-slew.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Jeden VCCIO (i VREF) na bank — standardy przydziela się do banków | planowanie pinów |
| LVTTL: V_IH ≥ 2,0 V, V_IL ≤ 0,8 V; pin 3,3 V nie przyjmuje 5 V | poziomy |
| LVDS: 3,5 mA, 100 Ω na końcu, ok. 350 mV, wspólne ok. 1,2 V | łącza różnicowe |
| FR-4: ok. 15 cm/ns (6,7 ps/mm); linia transmisyjna, gdy opóźnienie > ok. t_r/6 | czy terminować |
| Γ = (Z_L − Z0)/(Z_L + Z0) | odbicia |
| Terminacja szeregowa R_s ≈ Z0 − R_wy (punkt–punkt), równoległa Z0 na końcu, LVDS 100 Ω różnicowo | dopasowanie |
| Najmniejszy prąd i najwolniejszy slew, które spełniają czasy | siła sterowania |

## [22.02 — Rejestry DDR w I/O i interfejsy źródłowo-synchroniczne](22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| Rejestry DDR i rejestry interfejsu — w bloku I/O (ALTDDIO, ODDR/IDDR), nigdy multiplekser na zegarze w logice | każdy szybki interfejs |
| Zegar przesyłany przez taki sam rejestr DDR jak dane (1/0) — wyrównanie do krawędzi | nadajnik |
| Okno: przesunięcie zegara w [t_SU, UI − t_H], szerokość UI − t_SU − t_H minus przekos i jitter | budżet czasowy |
| DDR: UI = T_clk / 2; ograniczenia wejścia i wyjścia dla obu zboczy (`-clock_fall -add_delay`) | STA |
| RGMII: 125 MHz DDR, zegar opóźniony o 1,5–2 ns (płytka albo RGMII-ID) | Ethernet 1 Gb/s |
| PRBS7 = x⁷ + x⁶ + 1, okres 127; kontroler samosynchronizujący; 1 błąd na łączu = 3 zgłoszenia | test łącza |

## [22.03 — LVDS i serializacja (SERDES)](22.03-lvds-i-serializacja-serdes.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| f_słowa = f_bit / N; zegar bitowy i słowa z jednego PLL | SERDES |
| Bitslip przesuwa granicę o 1 bit; po ≤ N próbach słowo wyrównane | synchronizacja słowa |
| Wzorzec treningowy bez symetrii obrotowej (np. 0x6B dla N = 8) | wyrównanie |
| Po bitslipie odczekaj opóźnienie potoku; ogłoś wyrównanie po kilku zgodnych słowach | automat |
| ADC: zegar ramki (FCO) deserializowany jak dane wyznacza granicę słowa | przetworniki |
| Para LVDS: 100 Ω, terminacja przy odbiorniku, długości w parze i między parami wyrównane | płytka |

## [22.04 — Transceivery wielogigabitowe: 8b/10b, 64b/66b i wyrównanie](22.04-transceivery-wielogigabitowe-8b-10b-64b-66b-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| 8b/10b: narzut 25 %, ciąg ≤ 5, RD = ±1, 12 znaków K, przecinek w K28.1/5/7 | 1G Ethernet, PCIe 1–2, SATA, JESD204B |
| K28.5 = 0011111010 (RD−) / 1100000101 (RD+) | wyrównanie, bezczynność |
| 64b/66b: nagłówek 01 dane / 10 sterowanie, skrambler x⁵⁸ + x³⁹ + 1, narzut 3,125 % | 10G+ Ethernet, JESD204C |
| 128b/130b: narzut 1,54 % | PCIe Gen3–Gen5 |
| Skrambler samosynchronizujący: 1 błąd → 3 błędy | BER za deskramblerem |
| ±100 ppm: różnica 1 znaku na 5000 — korekcja zegara znakami wypełnienia | bufor elastyczny |
| BER ≤ 10⁻¹², test PRBS31 | kwalifikacja łącza |

## [22.05 — Przegląd protokołów: PCIe, JESD204, Aurora, SATA](22.05-przeglad-protokolow-pcie-jesd204-aurora-sata.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| PCIe: Gen1 2,5 / Gen2 5 GT/s (8b/10b), Gen3 8 / Gen4 16 / Gen5 32 GT/s (128b/130b), Gen6 64 GT/s PAM4 | dobór generacji |
| PCIe: TLP + ACK/NAK z ponawianiem + kredyty; netto zależy od rozmiaru ładunku | przepustowość |
| JESD204B: 8b/10b do 12,5 Gb/s, CGS (K28.5) → ILAS → dane; JESD204C: 64b/66b do 32 Gb/s | przetworniki |
| Podklasa 1: SYSREF = deterministyczne opóźnienie, synchronizacja wielu przetworników | wielokanałowe układy |
| Aurora: lekki transport punkt–punkt, AXI4-Stream, bez adresów i ponawiania | FPGA ↔ FPGA |
| SATA: 1,5/3/6 Gb/s, 8b/10b, OOB (COMRESET/COMINIT/COMWAKE), prymitywy od K28.5 | dyski |

## [22.06 — FPGA na płytce PCB: zasilanie, sekwencjonowanie i planowanie pinów](22.06-fpga-na-plytce-pcb-zasilanie-sekwencjonowanie-i.md)

| Reguła lub liczba | Kiedy obowiązuje |
|-------------------|------------------|
| MAX 10 dwuzasilaniowy: VCC 1,2 V, VCCA 2,5 V, VCCIO na bank; ADC — osobne ciche zasilanie | DECA |
| Kolejność zasilań i czasy narastania — z Power Management Guide danej rodziny | projekt zasilania |
| Z_cel = ΔV_dop / ΔI w całym paśmie; kondensatory od bulk do 0,1 µF przy pinach | PDN |
| Zegary na dedykowane piny CLK (sieci globalne, PLL) | pinout |
| Pinout DDR i transceiverów z generatora IP | szybkie interfejsy |
| Pinout zatwierdzony dopiero po bezbłędnej kompilacji I/O | proces |
| Szacunek mocy wcześnie (EPE/XPE) — dobór regulatorów i chłodzenia | projekt płytki |
