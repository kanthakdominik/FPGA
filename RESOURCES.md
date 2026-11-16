# Źródła (anglojęzyczne)

[← README](README.md)

Tematy odwołują się do konkretnych rozdziałów i sekcji poniższych materiałów. Tu jest ich pełna lista z opisem, do czego się nadają. Pozycje płatne są oznaczone 💲 — podajemy tylko tytuł i zakres, bez treści.

## Kursy i podręczniki darmowe

| Źródło | Zakres | Moduły |
|--------|--------|--------|
| [HDLBits](https://hdlbits.01xz.net/) | Ok. 180 krótkich zadań z Verilogu sprawdzanych w przeglądarce — najlepszy trening „palców” | 01, 05, 07, 08 |
| [Nandland](https://nandland.com/) — R. Merrick | Przystępne wprowadzenie do FPGA, VHDL i Verilogu, przykłady UART, VGA, FIFO | 00, 04, 05, 20 |
| [ZipCPU — tutoriale i blog](https://zipcpu.com/) — D. Gisselquist | Verilog od podstaw, weryfikacja formalna, magistrale Wishbone i AXI, debug — praktyka z naciskiem na poprawność | 05, 13, 17, 21 |
| [Project F](https://projectf.io/) — W. Green | Grafika i wideo na FPGA w SystemVerilogu: taktowanie wideo, sprite'y, linie, bufor ramki | 24 |
| [fpga4fun](https://www.fpga4fun.com/) | Krótkie projekty: PWM, UART, I²C, HDMI, SPI, generatory | 20, 24 |
| [Free Range VHDL](https://github.com/fabriziotappero/Free-Range-VHDL-book) — B. Mealy, F. Tappero | Darmowa książka o VHDL od zera | 04 |
| [Doulos KnowHow](https://www.doulos.com/knowhow/) | Krótkie poradniki VHDL, SystemVerilog, UVM, Tcl od firmy szkoleniowej | 04, 06, 10, 11 |
| [ChipVerify](https://www.chipverify.com/) | Przewodnik po Verilogu, SystemVerilogu i UVM z przykładami | 05, 06, 10, 11 |
| [Verification Academy](https://verificationacademy.com/) — Siemens | Kursy wideo i *UVM Cookbook*: UVM, pokrycie, asercje, metody formalne (darmowa rejestracja) | 10, 11, 13 |
| [Parallel Programming for FPGAs](https://kastner.ucsd.edu/hlsbook/) — R. Kastner, J. Matai, S. Neuendorffer | Darmowa książka o HLS: FIR, FFT, sortowanie, potokowanie | 28 |
| [Digital Design and Computer Architecture (ETH Zürich)](https://safari.ethz.ch/digitaltechnik/) — O. Mutlu | Wykłady i laboratoria: logika, Verilog, mikroarchitektura procesora (nagrania na YouTube) | 01, 27 |
| [PySDR](https://pysdr.org/) — M. Lichtman | DSP i radio programowalne w Pythonie — modele referencyjne do modułu 26 | 26 |
| [The Scientist and Engineer's Guide to DSP](https://www.dspguide.com/) — S. W. Smith | Praktyczne DSP: splot, FFT, filtry | 19, 26 |

## Standardy języków

| Źródło | Zakres | Moduły |
|--------|--------|--------|
| [IEEE 1800-2023 SystemVerilog](https://ieeexplore.ieee.org/browse/standards/get-program/page) | Pełny standard SystemVeriloga (zawiera Verilog) — bezpłatnie w programie IEEE GET, sponsorowanym przez Accellera | 05, 06, 10 |
| [Accellera — UVM](https://www.accellera.org/downloads/standards/uvm) | Biblioteka referencyjna UVM i podręcznik użytkownika | 11 |
| IEEE 1076-2019 VHDL 💲 | Standard VHDL; w praktyce wystarczają książki i dokumentacja GHDL | 04 |

## Dokumentacja Altera — MAX 10 i Quartus

| Źródło | Zakres | Moduły |
|--------|--------|--------|
| [MAX 10 FPGA Device Overview](https://www.intel.com/content/www/us/en/docs/programmable/683658/) | Rodzina MAX 10: zasoby, warianty, obudowy | 02 |
| [MAX 10 FPGA Device Datasheet](https://www.intel.com/content/www/us/en/docs/programmable/683794/) | Parametry elektryczne i czasowe | 02, 14, 22 |
| [MAX 10 FPGA Configuration User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683865/) | Konfiguracja, podwójny obraz, pamięć UFM, Unique Chip ID | 02, 03, 18, 29 |
| [MAX 10 Embedded Multipliers User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683467/) | Bloki mnożarek 18 × 18 / 9 × 9: liczba w układach, tryby, wnioskowanie z HDL | 01, 19 |
| [MAX 10 Analog to Digital Converter User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683596/) | Wbudowane przetworniki ADC i czujnik temperatury | 20 |
| [MAX 10 FPGA Handbook (PDF)](https://www.intel.com/programmable/technical-pdfs/max10-handbook.pdf) | Wszystkie przewodniki MAX 10 w jednym pliku: architektura, I/O, zegary i PLL, pamięci, mnożarki, zasilanie, JTAG | 02, 15, 18, 22 |
| [Quartus Prime Standard Edition — Design Recommendations](https://www.intel.com/content/www/us/en/docs/programmable/683323/) | Zalecane style kodowania HDL, wnioskowanie pamięci i DSP, metastabilność | 07, 15, 18 |
| [Quartus Prime — przewodniki użytkownika](https://www.altera.com/design/guidance/software/quartus-user-guides) | Zbiór przewodników: kompilacja, Timing Analyzer, debug, Platform Designer, optymalizacja | 03, 14, 16, 17, 21 |
| [Altera FPGA Software Installation and Licensing](https://www.intel.com/content/www/us/en/docs/programmable/683472/) | Instalacja Quartusa i licencja Questa Starter | 00 |
| DECA User Manual (Terasic/Arrow, 2015) | Opis płytki, schemat blokowy, tabele pinów — pobierany ze strony płytki w Arrow | 00, plytka-deca |

## Dokumentacja AMD (porównanie ekosystemów)

| Źródło | Zakres | Moduły |
|--------|--------|--------|
| [UG901 — Vivado Synthesis](https://docs.amd.com/r/en-US/ug901-vivado-synthesis) | Synteza i style kodowania HDL w Vivado | 07 |
| [UG903 — Using Constraints](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints) | Ograniczenia XDC (składnia SDC) | 14 |
| [UG906 — Design Analysis and Closure Techniques](https://docs.amd.com/r/en-US/ug906-vivado-design-analysis) | Raporty czasowe, analiza CDC | 14, 15, 16 |
| [UG949 — UltraFast Design Methodology Guide](https://docs.amd.com/r/en-US/ug949-vivado-design-methodology) | Metodyka projektowania i zamykania timingu — warto przeczytać niezależnie od producenta | 07, 15, 16, 30 |

## Artykuły klasyczne

| Źródło | Zakres | Moduły |
|--------|--------|--------|
| [Sunburst Design — artykuły C. Cummingsa](http://www.sunburst-design.com/papers/) | *Nonblocking Assignments in Verilog Synthesis*, *Clock Domain Crossing Design & Verification Techniques*, *Simulation and Synthesis Techniques for Asynchronous FIFO Design*, *Synchronous Resets? Asynchronous Resets?*, *Coding And Scripting Techniques For FSM Designs* | 05, 08, 15 |

## Narzędzia — dokumentacja

| Źródło | Moduły |
|--------|--------|
| [GHDL](https://ghdl.github.io/ghdl/) · [Icarus Verilog](https://steveicarus.github.io/iverilog/) · [Verilator](https://verilator.org/guide/latest/) | 00, 09 |
| [Yosys i SymbiYosys](https://yosyshq.readthedocs.io/) | 03, 13 |
| [cocotb](https://docs.cocotb.org/) · [VUnit](https://vunit.github.io/) · [OSVVM](https://osvvm.org/) · [UVVM](https://github.com/UVVM/UVVM) | 12 |
| [LiteX](https://github.com/enjoy-digital/litex) · [NEORV32](https://github.com/stnolting/neorv32) · [PicoRV32](https://github.com/YosysHQ/picorv32) · [VexRiscv](https://github.com/SpinalHDL/VexRiscv) | 27 |
| [hls4ml](https://fastmachinelearning.org/hls4ml/) · [FINN](https://github.com/Xilinx/finn) · [Bambu](https://panda.deib.polimi.it/) | 28 |
| [PeakRDL / SystemRDL](https://peakrdl.readthedocs.io/) | 21 |

## Książki płatne 💲

| Tytuł | Zakres | Moduły |
|-------|--------|--------|
| P. P. Chu, *FPGA Prototyping by VHDL Examples* i *FPGA Prototyping by SystemVerilog Examples* | Projektowanie RTL na przykładach: liczniki, FSM, UART, PS/2, VGA, procesor | 07, 08, 20, 24 |
| S. Harris, D. Harris, *Digital Design and Computer Architecture, RISC-V Edition* | Logika cyfrowa, HDL, procesor RISC-V jednocyklowy, wielocyklowy i potokowy | 01, 27 |
| S. Sutherland, *RTL Modeling with SystemVerilog for Simulation and Synthesis* | Syntezowalny SystemVerilog — podręcznik referencyjny | 06, 07 |
| P. J. Ashenden, *The Designer's Guide to VHDL* | Kompletny podręcznik VHDL | 04 |
| R. Merrick, *Getting Started with FPGAs* | Wprowadzenie dla początkujących, Verilog i VHDL równolegle | 00, 07 |
| S. Kilts, *Advanced FPGA Design* | Architektura, timing, CDC, optymalizacja | 15, 16 |
| C. Spear, G. Tumbush, *SystemVerilog for Verification* | Weryfikacja w SystemVerilogu: OOP, losowanie, pokrycie | 10 |
| R. Salemi, *The UVM Primer* | Krótkie, praktyczne wprowadzenie do UVM | 11 |
| E. Seligman, T. Schubert, M. V. A. K. Kumar, *Formal Verification* | Metody formalne w przemyśle | 13 |
| U. Meyer-Baese, *Digital Signal Processing with Field Programmable Gate Arrays* | DSP w FPGA: arytmetyka, FIR, IIR, CORDIC, FFT | 19, 26 |
| H. Johnson, M. Graham, *High-Speed Digital Design* | Integralność sygnałów, terminacja | 22 |

## Wideo

Kanały podane jako linki do wyszukiwania w YouTube.

| Kanał | Zakres | Moduły |
|-------|--------|--------|
| [Onur Mutlu Lectures — Digital Design and Computer Architecture](https://www.youtube.com/results?search_query=onur+mutlu+digital+design+and+computer+architecture) | Pełne wykłady ETH Zürich | 01, 27 |
| [Nandland](https://www.youtube.com/results?search_query=nandland+fpga) | Krótkie filmy o podstawach FPGA | 00, 07 |
| [Adam Taylor — FPGA](https://www.youtube.com/results?search_query=adam+taylor+fpga) | Praktyka zawodowa, Vivado, SoC | 16, 27 |
| [Verification Academy — UVM Basics](https://www.youtube.com/results?search_query=verification+academy+uvm+basics) | Seria wprowadzająca do UVM | 11 |
