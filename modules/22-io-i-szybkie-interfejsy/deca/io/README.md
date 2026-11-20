# DECA — standardy I/O i łącze DDR (moduł 22)

| Pin złącza | Sygnał | Ustawienia (utworz_projekt.tcl) |
|---|---|---|
| GPIO0_D[0] | 25 MHz | 3.3-V LVTTL, 4 mA, SLEW_RATE 0 (wolno) |
| GPIO0_D[1] | 25 MHz | 4 mA, SLEW_RATE 2 (szybko) |
| GPIO0_D[2] | 25 MHz | 8 mA, SLEW_RATE 0 |
| GPIO0_D[3] | 25 MHz | 8 mA, SLEW_RATE 2 |
| GPIO0_D[4] | zegar 50 MHz z rejestru DDR | 8 mA, SLEW_RATE 2 |
| GPIO0_D[5] | dane PRBS7 DDR, 100 Mb/s | 8 mA, SLEW_RATE 2 |
| GPIO0_D[6] | wejście DDR — **zwora z GPIO0_D[5]** | rejestr wejściowy w bloku I/O |

```bash
make && make sram          # JEZYK=vhdl albo sv dla modułu nadrzędnego
```

- Oscyloskop (sonda z krótką masą, pasmo ≥ 200 MHz) na D0…D3: porównanie czasów narastania i dzwonienia ([22.01](../../22.01-standardy-i-o-terminacja-sila-sterowania-i-slew.md)).
- Zwora D5 → D6: LED[0] — kontroler PRBS zsynchronizowany, LED[7:1] — liczba błędów (KEY[1] kasuje). SW[0] przełącza próbkowanie
  na zegar odwrócony — w jednym z położeń łącze powinno pracować bez błędów, w drugim (próbkowanie blisko zmiany danych)
  pojawiają się błędy albo brak synchronizacji ([22.02](../../22.02-rejestry-ddr-w-i-o-i-interfejsy-zrodlowo.md)). Dłuższy przewód zwory przesuwa okno.
- Jeśli Quartus odrzuci któreś ustawienie (dostępne wartości zależą od wersji i standardu), sprawdź je w *Pin Planner → All Pins*.

Projekt nie był kompilowany w Quartusie w CI — CI sprawdza moduł nadrzędny w symulatorach (wariant z modelami DDR).
