# Projekt DECA „uart” — echo UART 115 200 b/s

Projekt z tematu [20.01](../../20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md). DECA nie ma mostka USB-UART — potrzebna jest przejściówka **3,3 V** (np. FT232, CP2102, CH340) albo zwora.

## Połączenia (złącze GPIO0 / P8)

| Płytka | Przejściówka |
|---|---|
| `GPIO0_D[0]` (TX) | RX |
| `GPIO0_D[1]` (RX) | TX |
| GND | GND |

Bez przejściówki: zwora `GPIO0_D[0]` ↔ `GPIO0_D[1]` — napis wysłany przyciskiem KEY[1] wraca do odbiornika i ostatni znak (`\n`, 0x0A) widać na diodach.

## Uruchomienie

```bash
make && make sram
```

Terminal na komputerze: 115 200 b/s, 8 bitów, bez parzystości, 1 bit stopu (`picocom -b 115200 /dev/ttyUSB0`, PuTTY, Tera Term). Każdy wpisany znak wraca (echo); przy SW[0] w górze małe litery wracają jako wielkie. KEY[1] wysyła `DECA UART 115200 8N1`. LED[6:0] — kod ostatniego znaku, LED[7] — błąd ramki (np. zła szybkość w terminalu).
