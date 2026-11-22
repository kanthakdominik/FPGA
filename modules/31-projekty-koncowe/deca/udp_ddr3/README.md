# Projekt DECA „udp_ddr3” (31.04)

Nios V/m z własnym peryferium `udp_dma` z [31.04](../../31.04-projekt-4-system-nios-v-ddr3-strumien.md): procesor przygotowuje dane w buforze, a peryferium samo czyta je masterem Avalon-MM, buduje datagram UDP/IPv4 i wysyła przez PHY DP83620 (MII, 100 Mb/s).

## Kroki

```bash
make system      # qsys-script + qsys-generate: system_udp (Nios V/m, RAM 64 KB, JTAG UART, udp_dma)
make             # projekt Quartusa z utworz_projekt.tcl i kompilacja
make sram        # wgranie .sof
make bsp app     # w Nios V Command Shell: BSP z system_udp.sopcinfo i program z software/src
make pobierz     # wgranie programu i terminal JTAG UART
```

Komputer w sieci 192.168.1.0/24 z adresem 192.168.1.100, kabel do gniazda Ethernet DECA. Odbiór: skrypt [odbior_udp.py z modułu 25](../../../25-audio-i-ethernet/deca/udp/odbior_udp.py) (port 5006) albo dowolny program słuchający na porcie 5006. Program wysyła ramki na rozgłoszeniowy adres MAC — FPGA nie odpowiada na ARP (brak toru odbioru w tym projekcie).

## Wariant z DDR3

Domyślnie bufor leży w pamięci wewnętrznej (64 KB), żeby system dał się zbudować samym skryptem. Do pracy z DDR3:

1. W Platform Designer dodaj *DDR3 SDRAM Controller with UniPHY* z ustawieniami z [modułu 23](../../../23-pamieci-zewnetrzne/deca/ddr3/README.md) (zegar referencyjny `DDR3_CLK_50`, połowa częstotliwości na Avalon).
2. Podłącz interfejs `avl` kontrolera do `cpu.data_manager` i `udp.m0`; jako zegar systemu (procesor, RAM, `udp_dma`) użyj `afi_half_clk` kontrolera albo dodaj most przejścia zegara (*Avalon-MM Clock Crossing Bridge*).
3. Wyeksportuj interfejs pamięci (`memory`) i statusy (`local_cal_success`), dodaj piny `DDR3_*` do `deca_top` i przypisania pinów z modułu 23.
4. W programie umieść bufor w sekcji połączonej z DDR3 albo użyj adresu bazowego kontrolera z `system.h`.

## Zastrzeżenia

Projekt nie był kompilowany w Quartusie ani uruchamiany na płytce. Nazwy parametrów rdzeni w `system.tcl` i interfejsów wyeksportowanych przez Platform Designer zależą od wersji Quartusa. CI sprawdza `udp_dma` testbenchem w trzech językach (pamięć z losowymi opóźnieniami, odbiór i analiza ramek), kompiluje `deca_top` w symulatorach w wariancie bez systemu Platform Designer i sprawdza składnię programu C.
