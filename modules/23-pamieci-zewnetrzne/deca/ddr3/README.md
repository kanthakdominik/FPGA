# DECA — kontroler DDR3 (UniPHY) z generatorem ruchu (moduł 23)

Projekt nie ma własnego kodu HDL: kontroler i PHY generuje Quartus, a do testu służy **projekt przykładowy** (*example design*)
rdzenia z generatorem ruchu, który zapisuje i odczytuje całą pamięć i zgłasza wynik ([23.02](../../23.02-kontroler-ddr3-na-max-10-uniphy.md)).

## Kroki (Quartus Prime Lite/Standard z obsługą MAX 10)

1. Nowy projekt dla 10M50DAF484C6GES (albo otwórz dowolny projekt DECA i dodaj IP).
2. *IP Catalog → Memory Interfaces and Controllers → DDR3 SDRAM Controller with UniPHY*, nazwa np. `ddr3_uniphy`.
3. Zakładka **PHY Settings**: częstotliwość pamięci zgodna z instrukcją płytki DECA (dla MAX 10 do ok. 300 MHz), zegar
   referencyjny 50 MHz z pinu `DDR3_CLK_50`, *Rate on Avalon-MM interface*: *Half*.
4. Zakładka **Memory Parameters**: kość pamięci z instrukcji płytki (szerokość danych 16 bitów, pojemność, liczba banków,
   wiersze i kolumny), CL, CWL, czasy z karty katalogowej — albo gotowe ustawienia z pliku `.qprs`, jeśli producent płytki go
   dostarcza.
5. Zakładka **Board Settings**: przekosy i model obciążenia z instrukcji płytki (albo wartości domyślne — kalibracja przy starcie
   pokryje część różnic).
6. **Generate Example Design** — powstaje katalog z projektem `*_example_design` (kontroler + generator ruchu + skrypty TCL
   przypisań pinów) oraz projekt do symulacji z modelem pamięci.
7. W projekcie przykładowym: uruchom `*_pin_assignments.tcl` (*Tools → Tcl Scripts*), dopasuj nazwy pinów najwyższego poziomu
   do schematu DECA (pliki pinów płytki: `DDR3_*`), skompiluj, wgraj.
8. Sygnały `local_cal_success`, `local_cal_fail`, `pnf` / `pass` / `fail` generatora ruchu podłącz do diod (LED) albo podejrzyj
   w Signal Tap ([17](../../../17-debug-na-sprzecie/README.md)); raport kalibracji — *EMIF Debug Toolkit*.

Oczekiwany wynik: `local_cal_success = 1`, generator ruchu w stanie *pass*. Projekt nie był sprawdzany w CI (wymaga Quartusa
i generacji IP); jeśli w instrukcji DECA jest gotowy projekt demonstracyjny DDR3 od Terasic, można go użyć do porównania ustawień.
