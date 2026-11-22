# Projekt DECA „oscyloskop” (31.02)

Oscyloskop z [31.02](../../31.02-projekt-2-oscyloskop-na-wbudowanym-adc-z.md): wbudowany ADC MAX 10 (kanał 1, ADC1IN1), obraz 640×480 przez HDMI.

## Rdzenie IP

Jak w [module 20](../../../20-interfejsy-szeregowe/deca/adc/README.md), w tym katalogu:

1. `adc_pll` — ALTPLL, wejście 10 MHz (`ADC_CLK_10`), wyjście `c0` 10 MHz, wyjście `locked`, bez `areset`.
2. `adc_rdzen` — Modular ADC Core, **ADC Control Core Only**, zegar ADC 10 MHz, odniesienie wewnętrzne, **1 MSPS**, kanał **CH1**.

PLL zegara piksela (`altpll`) i rejestr DDR zegara HDMI (`altddio_out`) są wstawione wprost w `deca_top` (biblioteka `altera_mf`), jak w module 24.

## Kompilacja i obsługa

```bash
make            # utworzy projekt (doda oba .qip) i skompiluje
make sram
```

Sygnał na wejście analogowe ADC1IN1 płytki (zakres 0–2,5 V przy odniesieniu wewnętrznym — sprawdź w schemacie DECA, do którego złącza jest wyprowadzone, i nie przekraczaj zakresu). SW[0] — tryb auto, SW[1] — co 10. próbka, KEY[1] — poziom wyzwalania 1/4 → 1/2 → 3/4 zakresu, KEY[0] — reset. LED[0] — ADV7513 skonfigurowany, LED[2] — zrzut z wyzwolenia.

## Zastrzeżenia

Projekt nie był kompilowany w Quartusie ani uruchamiany na płytce. CI sprawdza rdzeń `oscyloskop` testbenchem (obie domeny zegara, analiza ramek obrazu) i kompiluje `deca_top` w symulatorach w wariancie bez rdzeni IP.
