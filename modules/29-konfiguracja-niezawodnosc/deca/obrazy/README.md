# DECA — dwa obrazy konfiguracji i przełączanie z logiki (moduł 29)

Projekt do [29.02](../../29.02-podwojny-obraz-i-zdalna-aktualizacja-w-max-10.md): ten sam kod skompilowany dwa razy z parametrem `OBRAZ` daje dwa obrazy, które trafiają do dwóch obszarów pamięci konfiguracji MAX 10 (CFM0 i CFM1, tryb **Dual Compressed Images**). Moduł [aktualizacja](../../hdl/verilog/aktualizacja.v) steruje rdzeniem **Dual Configuration Intel FPGA IP** (`altera_dual_boot`) i przełącza układ na drugi obraz.

| Element | Obraz 0 („fabryczny”) | Obraz 1 („aplikacja”) |
|---|---|---|
| LED[5:0] | wolne miganie LED[0] | biegnące światło |
| LED[6] | zgaszona | świeci |
| KEY[1] | przełącz na obraz 1 | przełącz na obraz 0 |

SW[0] — „CRC nowego obrazu poprawne”: przy 0 przełączenie jest odrzucane (LED[7] miga szybko ok. 2 s). SW[1] — zerowanie licznika nadzorującego (*user watchdog*) co ok. 0,67 s, jeśli został włączony w rdzeniu. KEY[0] — reset logiki. W czasie oczekiwania na rdzeń (600 taktów) LED[5:0] świecą wszystkie.

## Kroki

```bash
make system                 # qsys-script + qsys-generate: system_dual (rdzeń Dual Configuration)
make obraz0                 # projekt z OBRAZ=0, kompilacja, kopia output_files/obrazy.sof -> obraz0.sof
make obraz1                 # to samo z OBRAZ=1 -> obraz1.sof
```

Potem w Quartusie: *File → Convert Programming Files*: typ **Programmer Object File (.pof)**, tryb **Internal Configuration**, urządzenie 10M50DA; w *Input files to convert* dwie strony danych SOF — pierwsza (CFM0) z `obraz0.sof`, druga (CFM1) z `obraz1.sof`; w opcjach ustaw obraz startowy. *Save Conversion Setup* jako `obrazy.cof`, wtedy kolejne konwersje: `make pof`. Programowanie: Programmer, plik `.pof`, *Program/Configure* dla CFM0, CFM1 i UFM (albo `quartus_pgm -m jtag -o "p;obrazy.pof"`).

Po włączeniu zasilania układ startuje z obrazu wskazanego pinem CONFIG_SEL (w nowszych wersjach Quartusa — z ustawienia obrazu startowego w opcjach urządzenia i pliku `.pof`). Rdzeń wybiera obraz w rejestrze wejściowym (`config_sel_overwrite` = 1), więc przełączenie z KEY[1] działa niezależnie od pinu. Po wyłączeniu zasilania wybór z rejestru ginie — wraca obraz startowy.

## Zastrzeżenia

Projekt nie był kompilowany w Quartusie ani sprawdzany na płytce. Nazwy interfejsów rdzenia w `system.tcl` (`clk`, `nreset`, `avalon`), przypisanie `INTERNAL_FLASH_UPDATE_MODE "DUAL IMAGES"` w `utworz_projekt.tcl` i układ okna konwersji zależą od wersji Quartusa — przy rozbieżności popraw je według *MAX 10 FPGA Configuration User Guide* (UG-M10CONFIG). CI sprawdza moduły `aktualizacja` i `crc32` testbenchem z modelem rdzenia w trzech językach i kompiluje moduł nadrzędny w symulatorach (wariant `DECA_SYMULACJA` bez rdzenia).
