# Narzędzia (wszystkie darmowe)

[← README](README.md)

Instalację krok po kroku opisują tematy [00.03](modules/00-srodowisko-pracy/00.03-instalacja-quartus-prime-lite-i-questa-starter.md) i [00.04](modules/00-srodowisko-pracy/00.04-instalacja-ghdl-icarus-verilog-verilator-i-oss.md). Wszystkie narzędzia działają na Windows i Linux; na macOS działają tylko narzędzia otwarte (Quartus i Questa wymagają maszyny wirtualnej).

## Altera — projekty na DECA (MAX 10)

| Narzędzie | Do czego | Uwagi |
|-----------|----------|-------|
| **Quartus Prime Lite Edition** | Synteza, implementacja i programowanie MAX 10; w zestawie Timing Analyzer, Signal Tap, Platform Designer, Power Analyzer | Bez licencji. Przy instalacji wystarczy obsługa rodziny MAX 10. Kilkanaście GB na dysku — instalacja w [00.03](modules/00-srodowisko-pracy/00.03-instalacja-quartus-prime-lite-i-questa-starter.md) |
| **Questa — Altera FPGA Starter Edition** | Symulator VHDL, Verilog i SystemVerilog (także klasy i UVM, z ograniczeniem wydajności) | Wymaga darmowej licencji z Self Service Licensing Center, ważnej 12 miesięcy |
| **Sterownik USB-Blaster II** | Programowanie DECA przez wbudowany programator | Instalowany razem z Quartusem; na Linuksie trzeba dodać regułę udev |
| **Ashling RiscFree IDE** | Oprogramowanie w C dla procesora Nios V (moduł 27) | Pobierane osobno ze strony Altery |

## Symulacja i weryfikacja (otwarte)

| Narzędzie | Do czego | Link |
|-----------|----------|------|
| **GHDL** | Symulator VHDL (VHDL-2008); uruchamia testbenche VHDL w CI | [github.com/ghdl/ghdl](https://github.com/ghdl/ghdl) |
| **Icarus Verilog** | Symulator Verilog; uruchamia testbenche Verilog w CI | [steveicarus.github.io/iverilog](https://steveicarus.github.io/iverilog/) |
| **Verilator** | Najszybszy otwarty symulator (SystemVerilog → C++), lint; uruchamia testbenche SV w CI | [verilator.org](https://www.veripool.org/verilator/) |
| **cocotb** | Testbenche w Pythonie dla dowolnego symulatora (moduł 12) | [cocotb.org](https://www.cocotb.org/) |
| **VUnit** | Testy jednostkowe dla VHDL i SystemVeriloga (moduł 12) | [vunit.github.io](https://vunit.github.io/) |
| **OSVVM**, **UVVM** | Biblioteki i metodologie weryfikacji w VHDL (moduł 12) | [osvvm.org](https://osvvm.org/) · [github.com/UVVM/UVVM](https://github.com/UVVM/UVVM) |
| **SymbiYosys** | Weryfikacja formalna (moduł 13) | [symbiyosys.readthedocs.io](https://symbiyosys.readthedocs.io/) |
| **EDA Playground** | Symulatory komercyjne i otwarte w przeglądarce — także UVM, bez instalacji | [edaplayground.com](https://www.edaplayground.com/) |

## Synteza i implementacja (otwarte)

| Narzędzie | Do czego | Link |
|-----------|----------|------|
| **OSS CAD Suite** | Jedna paczka: Yosys, nextpnr, SymbiYosys, GHDL, Icarus, Verilator, GTKWave, cocotb | [github.com/YosysHQ/oss-cad-suite-build](https://github.com/YosysHQ/oss-cad-suite-build) |
| **Yosys** | Synteza otwarta; podgląd schematu RTL (`show`), statystyki zasobów | [yosyshq.net/yosys](https://yosyshq.net/yosys/) |
| **nextpnr** | Rozmieszczanie i trasowanie dla Lattice iCE40/ECP5, Gowin i innych (moduł 03) | [github.com/YosysHQ/nextpnr](https://github.com/YosysHQ/nextpnr) |

## Przebiegi, edycja, styl

| Narzędzie | Do czego | Link |
|-----------|----------|------|
| **GTKWave** | Klasyczna przeglądarka przebiegów (VCD, FST, GHW) | [gtkwave.github.io/gtkwave](https://gtkwave.github.io/gtkwave/) |
| **Surfer** | Nowoczesna przeglądarka przebiegów, także w przeglądarce internetowej | [surfer-project.org](https://surfer-project.org/) |
| **VS Code + TerosHDL** | Edytor z obsługą trzech języków, lint, schematy, dokumentacja | [terostechnology.github.io](https://terostechnology.github.io/) |
| **Verible** | Formatowanie i lint SystemVeriloga | [github.com/chipsalliance/verible](https://github.com/chipsalliance/verible) |
| **VSG** (VHDL Style Guide) | Formatowanie i sprawdzanie stylu VHDL | [github.com/jeremiah-c-leary/vhdl-style-guide](https://github.com/jeremiah-c-leary/vhdl-style-guide) |
| **WaveDrom** | Diagramy czasowe z opisu tekstowego | [wavedrom.com](https://wavedrom.com/) |

## Opcjonalnie — inne ekosystemy

| Narzędzie | Do czego | Uwagi |
|-----------|----------|-------|
| **AMD Vivado ML Standard** | Porównanie z ekosystemem AMD: raporty, XDC, ILA, IP Integrator (moduły 14, 17, 21) | Darmowa wersja dla mniejszych układów; ok. 100 GB |
| **Python 3** z numpy, scipy, matplotlib | Modele referencyjne, generowanie wektorów testowych, DSP (moduły 12, 19, 26) | |

## Sprzęt

| Co | Do czego |
|----|----------|
| **Arrow DECA** (MAX 10, 10M50DAF484C6G) | Główna płytka repozytorium — [opis](plytka-deca/README.md) |
| Zasilacz 5 V, min. 3 A | Zasilanie DECA |
| Monitor z wejściem HDMI | Moduł 24 |
| Konwerter USB-UART 3,3 V | Moduły 20 i 31 — UART z własnego RTL wyprowadza się na złącze rozszerzeń (programy na Nios V mogą też użyć JTAG UART przez USB-Blaster) |
| Tani analizator logiczny USB (8 kanałów) + PulseView | Moduł 17 |
| Kamera z interfejsem MIPI kompatybilna z DECA | Moduł 24, projekt 5 |
