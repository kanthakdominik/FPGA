# Projekt DECA: licznik w pamięci flash użytkownika (UFM)

Projekt do tematu [18.05](../../18.05-pamiec-flash-uzytkownika-w-max-10-ufm.md). Logika (`deca_top`, `ufm_sterownik`) jest w repozytorium; rdzeń **On-Chip Flash** trzeba raz wygenerować w Quartusie, bo jego netlista zależy od układu i trybu konfiguracji.

## Generowanie rdzenia `ufm_flash`

1. Quartus: *Tools → IP Catalog → Basic Functions → On Chip Memory → On-Chip Flash* (Platform Designer otwiera edytor parametrów).
2. Nazwa: `ufm_flash`, katalog: ten katalog (`modules/18-pamieci/deca/ufm`).
3. Parametry:
   - *Device*: 10M50DAF484C6GES (płytka DECA), *Configuration mode*: taki sam jak w ustawieniach projektu (*Assignments → Device → Device and Pin Options → Configuration*),
   - *Data interface*: **Parallel**, *Read burst mode*: **Incrementing**, *Read burst count*: 1,
   - *Access mode*: **Read and write** dla UFM1 (sektor 1) i UFM0, **Hidden** dla sektorów konfiguracji (CFM),
   - *Clock frequency*: 50 MHz.
4. *Generate HDL*: synteza Verilog albo VHDL (zgodnie z językiem projektu).
5. Sprawdź szerokość portu `avmm_data_addr` w wygenerowanym `ufm_flash.v`/`.vhd` i ustaw tę samą wartość `FLASH_AW` w `deca_top` (domyślnie 17).
6. `make` — `utworz_projekt.tcl` dodaje `ufm_flash/synthesis/ufm_flash.qip` do projektu.

## Uruchomienie

```bash
make            # projekt + kompilacja
make flash      # zapis do pamięci konfiguracji (.pof) — po wyłączeniu zasilania projekt startuje sam
```

Naciśnij KEY[1] kilka razy (LED[6:0] — licznik), wyłącz i włącz zasilanie: licznik ma tę samą wartość. KEY[1] przy SW[0] w górze — kasowanie (licznik 0). LED[7] — błąd zgłoszony przez rdzeń. Uwaga: ponowne wgranie `.pof` programuje całą pamięć flash i kasuje UFM.

Sterownik i jego model rdzenia są sprawdzane w symulacji (`hdl/*/tb_ufm_sterownik.*`); samego rdzenia Quartusa nie ma w CI.
