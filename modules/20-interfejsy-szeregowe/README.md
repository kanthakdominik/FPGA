# 20 — Interfejsy szeregowe niskiej szybkości

> **Część V** · **Oznaczenia:** 🛠️💼 · **Ścieżki:** RTL, DECA · **Szacowany czas:** ok. 16 h · **Status:** 🔲 szkielet

## Po co ten moduł

UART, SPI, I²C, PWM i enkodery — klasyczne zadania rekrutacyjne i podstawa komunikacji z czujnikami. Na DECA podłączysz wbudowane czujniki i przetwornik ADC MAX 10.

## Wymagane wcześniej

[08 — Automaty stanów i sterowanie](../08-automaty-stanow/README.md)

## Tematy

| # | Temat | Kod | DECA | Status |
|---|-------|-----|------|--------|
| 20.01 | [UART: nadajnik, odbiornik i nadpróbkowanie](20.01-uart-nadajnik-odbiornik-i-nadprobkowanie.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 20.02 | [SPI: master i slave, tryby CPOL/CPHA](20.02-spi-master-i-slave-tryby-cpol-cpha.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 20.03 | [I²C: master, open-drain i rozciąganie zegara](20.03-i2c-master-open-drain-i-rozciaganie-zegara.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 20.04 | [PWM, enkodery kwadraturowe i serwomechanizmy](20.04-pwm-enkodery-kwadraturowe-i-serwomechanizmy.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 20.05 | [Czujniki na DECA: akcelerometr, temperatura i wilgotność](20.05-czujniki-na-deca-akcelerometr-temperatura-i.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |
| 20.06 | [Wbudowany przetwornik ADC w MAX 10](20.06-wbudowany-przetwornik-adc-w-max-10.md) | VHDL · Verilog · SystemVerilog | 🛠️ | 🔲 |

## Po tym module potrafisz

- zaprojektować nadajnik i odbiornik UART z nadpróbkowaniem,
- zaprojektować SPI master i slave w czterech trybach,
- obsłużyć I²C z liniami open-drain i rozciąganiem zegara,
- generować PWM i dekodować enkoder kwadraturowy,
- odczytać czujniki DECA i wbudowany ADC MAX 10.

## Kod w module

- `hdl/` — moduły i samosprawdzające się testbenche, osobno dla każdego języka (`vhdl/`, `verilog/`, `sv/`); uruchamiane automatycznie w GitHub Actions ([zasady](../../docs/STYL-KODU.md)).
- `deca/` — projekty Quartusa dla płytki Arrow DECA: moduł nadrzędny, przypisania pinów (`.qsf`), ograniczenia czasowe (`.sdc`) ([opis płytki](../../plytka-deca/README.md)).

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
