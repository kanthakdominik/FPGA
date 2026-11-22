# 20 — Interfejsy szeregowe niskiej szybkości

> **Część V** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 16 h

## Po co ten moduł

UART, SPI, I²C, PWM i enkodery — klasyczne zadania rekrutacyjne i podstawa komunikacji z czujnikami. Na DECA podłączysz wbudowane czujniki i przetwornik ADC MAX 10.

## Wymagane wcześniej

[08 — Automaty stanów i sterowanie](../08-automaty-stanow/README.md)

## Tematy

| # | Temat | Kod | DECA |
|---|-------|-----|------|
| 20.01 | [UART: nadajnik, odbiornik i nadpróbkowanie](20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 20.02 | [SPI: master i slave, tryby CPOL/CPHA](20.02-spi-master-i-slave-tryby-cpol-cpha.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 20.03 | [I²C: master, open-drain i rozciąganie zegara](20.03-i2c-master-open-drain-i-rozciaganie-zegara.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 20.04 | [PWM, enkodery kwadraturowe i serwomechanizmy](20.04-pwm-enkodery-kwadraturowe-i-serwomechanizmy.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 20.05 | [Czujniki na DECA: akcelerometr, temperatura i wilgotność](20.05-czujniki-na-deca-akcelerometr-temperatura-i.md) | VHDL · Verilog · SystemVerilog | 🛠️ |
| 20.06 | [Wbudowany przetwornik ADC w MAX 10](20.06-wbudowany-przetwornik-adc-w-max-10.md) | VHDL · Verilog · SystemVerilog | 🛠️ |

## Po tym module potrafisz

- zaprojektować nadajnik i odbiornik UART z nadpróbkowaniem,
- zaprojektować SPI master i slave w czterech trybach,
- obsłużyć I²C z liniami open-drain i rozciąganiem zegara,
- generować PWM i dekodować enkoder kwadraturowy,
- odczytać czujniki DECA i wbudowany ADC MAX 10.

## Układy w module

- **`uart_tx`, `uart_rx`** — UART z akumulatorem fazy (dowolna szybkość z dowolnego zegara), parzystość, odbiornik z nadpróbkowaniem 16×, decyzją większościową i wykrywaniem błędów ramki i parzystości ([20.01](20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md)).
- **`spi_master`, `spi_slave`** — SPI w czterech trybach wybieranych w czasie pracy, transakcje wielosłowowe, slave z nadpróbkowaniem i kolejką słów do nadania ([20.02](20.02-spi-master-i-slave-tryby-cpol-cpha.md)).
- **`i2c_master`** — I²C z interfejsem rozkazów (START, STOP, zapis, odczyt), open-drain, rozciąganie zegara, arbitraż ([20.03](20.03-i2c-master-open-drain-i-rozciaganie-zegara.md)).
- **`pwm_mostek`, `serwo`, `enkoder`** — PWM centrowany z rejestrem cieniowym i czasem martwym, impuls serwomechanizmu, dekoder enkodera ×4 z filtrem i licznikiem błędów ([20.04](20.04-pwm-enkodery-kwadraturowe-i-serwomechanizmy.md)).
- **`akcel_lis2dh12`, `temp_lm71`, `hdc1000`** — sterowniki czujników płytki DECA: sekwencja startowa, identyfikator, konfiguracja, cykliczny odczyt, przeliczenie na jednostki, obsługa NACK ([20.05](20.05-czujniki-na-deca-akcelerometr-temperatura-i.md)).
- **`adc_sekwencer`, `adc_srednia`, `tsd_temperatura`** — sekwencer kanałów dla rdzenia ADC MAX 10 (*ADC Control Core Only*), średnia z decymacją, przeliczenie kodu termodiody na °C ([20.06](20.06-wbudowany-przetwornik-adc-w-max-10.md)).

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche w trzech językach (`vhdl/`, `verilog/`, `sv/`), uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)); testbenche zawierają behawioralne modele czujników (LIS2DH12, LM71, HDC1000), slave'a I²C typu EEPROM z rozciąganiem zegara i rdzenia ADC MAX 10. `hdl/dane/` — [gen_tsd.py](hdl/dane/gen_tsd.py): tablica przeliczenia kodu termodiody z tabeli Intel UG 683596 (`tsd_temp.hex`).
- `deca/` — projekty dla płytki Arrow DECA: [uart](deca/uart/) (echo przez przejściówkę USB-UART 3,3 V), [czujniki](deca/czujniki/) (trzy czujniki płytki, diody i telemetria UART), [naped](deca/naped/) (PWM z czasem martwym, serwo, enkoder na złączu GPIO), [adc](deca/adc/) (wbudowany ADC i termodioda; rdzenie IP generowane w Quartusie według [README](deca/adc/README.md)). Każdy: `deca_top` w trzech językach, ograniczenia czasowe (`.sdc`) i `utworz_projekt.tcl` z przypisaniami pinów z [plytka-deca/deca_piny.tcl](../../plytka-deca/deca_piny.tcl) ([opis płytki](../../plytka-deca/README.md)).
- CI: testbenche, lint, synteza i kompilacja modułów DECA w zadaniach ogólnych w [checks.yml](../../.github/workflows/checks.yml).
- Lint: kod Verilog i SystemVerilog z `hdl/` przechodzi `verilator --lint-only -Wall` bez ostrzeżeń — sprawdzane w CI ([07.09](../07-kodowanie-pod-synteze/07.09-styl-kodu-lint-i-przeglady-verilator-verible-vsg.md)).

## Powtórka

- [Ściąga modułu](SCIAGA.md) — reguły i liczby do zapamiętania na jednej stronie.
- Pytania rekrutacyjne z tego modułu trafiają też do [rozmowa-kwalifikacyjna/pytania.md](../../rozmowa-kwalifikacyjna/pytania.md).

## Postęp

- [ ] 20.01 UART: nadajnik, odbiornik i nadpróbkowanie
- [ ] 20.02 SPI: master i slave, tryby CPOL/CPHA
- [ ] 20.03 I²C: master, open-drain i rozciąganie zegara
- [ ] 20.04 PWM, enkodery kwadraturowe i serwomechanizmy
- [ ] 20.05 Czujniki na DECA: akcelerometr, temperatura i wilgotność
- [ ] 20.06 Wbudowany przetwornik ADC w MAX 10
