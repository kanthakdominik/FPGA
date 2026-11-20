# Projekt DECA „adc” — wbudowany przetwornik ADC MAX 10

Projekt z tematu [20.06](../../20.06-wbudowany-przetwornik-adc-w-max-10.md): sekwencer kanałów, uśrednianie i przeliczenie kodu termodiody na °C. Rdzeni IP nie ma w repozytorium — generuje się je raz w Quartusie, w tym katalogu.

## 1. PLL zegara ADC — `adc_pll`

*IP Catalog → Basic Functions → Clocks; PLLs and Resets → PLL → ALTPLL*, nazwa pliku `adc_pll` (Verilog albo VHDL):

- częstotliwość wejściowa `inclk0`: **10 MHz** (wejście `ADC_CLK_10` płytki),
- wyłączyć wejście `areset`, zostawić wyjście `locked`,
- wyjście `c0`: **10 MHz** (mnożnik 1, dzielnik 1) — ADC MAX 10 musi dostać zegar z wyjścia PLL.

## 2. Rdzeń ADC — `adc_rdzen`

*IP Catalog → Basic Functions → Analog to Digital Converter → Modular ADC core*, nazwa `adc_rdzen` (Platform Designer generuje go jako system):

- **Core Configuration: ADC Control Core Only**,
- ADC Input Clock: **10 MHz**, Reference Voltage Source: **Internal**, Sampling rate: **1 MHz**,
- zakładka *Channels*: włączyć **CH1** (ADC1IN1) i **TSD** (termodioda, kanał 17),
- *Generate HDL* — powstaje `adc_rdzen/synthesis/adc_rdzen.qip`.

Nazwy portów rdzenia muszą zgadzać się z `deca_top`: `clock_clk`, `reset_sink_reset_n`, `adc_pll_clock_clk`, `adc_pll_locked_export`, `command_*`, `response_*`.

## 3. Kompilacja

```bash
make            # utworzy projekt (doda oba .qip) i skompiluje
make sram
```

## Na płytce

- SW[0] = 0 — linijka diod pokazuje napięcie na ADC1IN1 (złącze P9; zakres 0–2,5 V — **nie podawać wyższego napięcia**),
- SW[0] = 1 — temperatura układu FPGA w °C (binarnie), z tablicy przeliczenia termodiody,
- KEY[0] — reset (logika rusza po zablokowaniu PLL).
