# DECA — rejestry przez JTAG (moduł 21)

System Platform Designer z mostkiem **JTAG to Avalon Master Bridge** i rdzeniem [avmm_rejestry](../../hdl/verilog/avmm_rejestry.v)
([21.02](../../21.02-rejestry-sterujace-axi4-lite-i-avalon-mm.md), [21.06](../../21.06-platform-designer-i-ip-integrator.md)).
Rejestry czyta się i zapisuje z komputera przez USB-Blaster płytki — bez przejściówek.

| Adres | Rejestr | Na płytce |
|---|---|---|
| 0x00 | ID (RO) = 0x21020001 | — |
| 0x04 | STER (RW) | LED[6:0] = STER[6:0] |
| 0x08 | STAN (RO) | bity 3:0 = SW1 SW0 KEY1 KEY0 |
| 0x0C | PRZER (W1C) | bit 0 ustawia naciśnięcie KEY1 |
| 0x10 | MASKA (RW) | LED[7] = irq = \|(PRZER & MASKA) |
| 0x14 | SKRYTKA (RW) | — |

## Kroki

```bash
make system            # qsys-script + qsys-generate: system_rej.qsys i system_rej/synthesis/
make                   # projekt i kompilacja (JEZYK=vhdl albo sv dla modułu nadrzędnego)
make sram
make konsola           # system-console --script=konsola.tcl
```

W GUI: Platform Designer → otwórz `system_rej.qsys` (po `make system`) — komponent „Rejestry kursu FPGA (21.02)”
z grupy *Kurs FPGA* pochodzi z [avmm_rejestry_hw.tcl](avmm_rejestry_hw.tcl). Ręcznie: *New system* → *Clock Source*,
*JTAG to Avalon Master Bridge*, *Rejestry kursu FPGA*; połączenia zegara, resetu i `master` → `s0`; adres bazowy 0;
eksport `clk`, `reset` i conduitu `uklad`; *Generate HDL*.

Interaktywnie w System Console (*Tools → System Debugging Tools → System Console* w Quartusie):

```tcl
set m [lindex [get_service_paths master] 0]
open_service master $m
master_read_32 $m 0x00 1
master_write_32 $m 0x04 0x7F
```

Projekt nie był kompilowany w Quartusie w CI (Quartusa tam nie ma) — CI sprawdza tylko moduł nadrzędny
w symulatorach (wariant `DECA_SYMULACJA` w Verilogu i SV z samym rdzeniem rejestrów).
