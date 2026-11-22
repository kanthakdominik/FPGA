# DECA — Nios V z własnym peryferium PWM (moduł 27)

System Platform Designer `system_niosv` ([27.02](../../27.02-nios-v-risc-v-w-platform-designer-na-deca.md), [27.03](../../27.03-wlasny-peryferial-z-rejestrami-i-sterownik-w-c.md)): procesor **Nios V/m** (RISC-V RV32I), 64 KB pamięci wewnętrznej, **JTAG UART** (printf przez USB-Blaster płytki), **PIO** na LED[6:0] i komponent [pwm_avl](../../hdl/verilog/pwm_avl.v) z opisem [pwm_avl_hw.tcl](pwm_avl_hw.tcl) na LED[7]. Program [software/src/main.c](software/src/main.c) używa sterownika [pwm.h](../../program/c/pwm.h) — tego samego, który w CI działa na własnym rdzeniu `rv_soc`.

| Adres (bajty) | Element | Uwagi |
|---|---|---|
| 0x0000_0000 | `ram.s1` — 64 KB | program i dane; wektor resetu |
| 0x0002_0000 | `jtag_uart` | `printf` z HAL |
| 0x0002_0010 | `led` (PIO, 7 bitów) | LED[6:0] (logika ujemna w `deca_top`) |
| 0x0002_0020 | `pwm` (`pwm_avl`) | STER, OKRES, WYPELN, STATUS; przerwanie nr 1 |
| przydzielane | `cpu.dm_agent`, `cpu.timer_sw_agent` | moduł debugowania, licznik czasu i przerwanie programowe rdzenia |

## Kroki

Wymagany Quartus Prime Lite/Standard z obsługą Nios V (od 23.1 w wersji Lite) i narzędzia Nios V (*Nios V Command Shell*: `niosv-bsp`, `niosv-app`, `niosv-download`, kompilator RISC-V, CMake).

```bash
make system            # qsys-script + qsys-generate: system_niosv.qsys, .sopcinfo i HDL w system_niosv/
make                   # projekt Quartusa i kompilacja (JEZYK=vhdl albo sv — moduł nadrzędny)
make sram              # konfiguracja FPGA przez JTAG
# w Nios V Command Shell:
make bsp               # niosv-bsp: pakiet HAL z system_niosv.sopcinfo -> software/bsp
make app               # niosv-app + cmake + make: software/app/build/*.elf
make pobierz           # niosv-download -g (ładowanie i start przez moduł debugowania) + juart-terminal
```

Składnia `niosv-bsp` różni się między wersjami: w Quartus Prime Standard/Lite podaje się plik `.sopcinfo` (`--sopcinfo=`), w Pro plik `.qsys` i projekt (`-s=system_niosv.qsys -p=niosv.qpf`). Nazwę pliku `.elf` w `software/app/build` nadaje `niosv-app` (od nazwy katalogu aplikacji) — w razie różnicy popraw cel `pobierz`.

Ręcznie w GUI: Platform Designer → *New system*: *Clock Source*, *Nios V/m Microcontroller*, *On-Chip Memory (RAM or ROM)* 64 KB, *JTAG UART*, *PIO* (7 bitów, wyjście), *PWM kursu FPGA (27.03)* z grupy *Kurs FPGA*; połączenia jak w [system.tcl](system.tcl), w parametrach Nios V *Reset Agent* = `ram.s1`; *System → Assign Base Addresses*; eksport `clk`, `reset`, `led` i `pwm`; *Generate HDL*.

## Co widać

- terminal JTAG UART: nagłówek z częstotliwością zegara i adresem PWM, co 4 s linia z licznikiem i liczbą okresów PWM,
- LED[6:0]: licznik binarny co 0,5 s (z liczby przerwań PWM — 1 ms każde),
- LED[7]: płynne rozjaśnianie i ściemnianie (wypełnienie zmieniane w procedurze obsługi przerwania).

Projekt nie był kompilowany w Quartusie ani uruchamiany na płytce w ramach CI (Quartusa i narzędzi Nios V tam nie ma). CI sprawdza moduł nadrzędny w symulatorach (wariant `DECA_SYMULACJA` z samym `pwm_avl`), peryferium testbenchem w trzech językach i sterownik `pwm.h` programem w C na własnym rdzeniu `rv_soc` ([program/c](../../program/c)). Nazwy parametrów rdzenia w `system.tcl` (`resetSlave`, `resetOffset`) i makr w `system.h` (`PWM_IRQ_INTERRUPT_CONTROLLER_ID`) mogą zależeć od wersji narzędzi.
