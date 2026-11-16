# Styl kodu i układ katalogów

Zasady wspólne dla wszystkich przykładów w repozytorium. Dzięki nim ten sam układ wygląda podobnie w trzech językach, testbenche uruchamiają się automatycznie, a projekty na DECA dają się odtworzyć jednym poleceniem.

[← README](../README.md)

## Układ katalogów modułu

```text
modules/07-kodowanie-pod-synteze/
├── README.md, SCIAGA.md, 07.01-….md …
├── hdl/
│   ├── vhdl/      licznik.vhd   tb_licznik.vhd
│   ├── verilog/   licznik.v     tb_licznik.v
│   └── sv/        licznik.sv    tb_licznik.sv
└── deca/
    └── licznik/
        ├── deca_top.vhd  deca_top.v  deca_top.sv
        ├── licznik.sdc
        ├── utworz_projekt.tcl
        └── Makefile
```

- Jeden moduł (entity) w pliku; nazwa pliku = nazwa modułu.
- Testbench ma nazwę `tb_<moduł>` i leży obok testowanego modułu.
- Kod przenośny (bez prymitywów producenta) jest w `hdl/`. Wszystko, co zależy od płytki lub układu — piny, PLL, rdzenie IP — jest w `deca/`.

## Nazwy

| Co | Zasada | Przykład |
|----|--------|----------|
| Moduły, sygnały, porty | `snake_case` | `uart_tx`, `bit_cnt` |
| Parametry, generiki, stałe | `UPPER_CASE` | `CLK_HZ`, `DATA_W` |
| Zegar | `clk`, przy wielu domenach `clk_<domena>` | `clk_pix`, `clk_sys` |
| Reset | `rst` — aktywny wysoki, synchroniczny; `rst_n` — aktywny niski | |
| Sygnał aktywny niskim stanem | przyrostek `_n` | `cs_n`, `key_n` |
| Wyjście rejestru i następny stan | `_q` / `_d` albo `_r` / `_next` — jedna konwencja w całym pliku | `cnt_q`, `cnt_d` |
| Typy wyliczeniowe stanów | `ST_` + nazwa | `ST_IDLE`, `ST_DATA` |

Nazwy w kodzie są po angielsku (tak wygląda kod w pracy), komentarze po polsku.

## VHDL

- Standard VHDL-2008 (`ghdl --std=08`, w Quartusie „VHDL 2008”).
- Tylko `ieee.std_logic_1164` i `ieee.numeric_std`. Nie używamy `std_logic_arith` ani `std_logic_unsigned`.
- Zbocze: `rising_edge(clk)`. Arytmetyka na typach `unsigned` / `signed`, nie na `std_logic_vector`.
- Testbench kończy się `std.env.finish`.

## Verilog

- Standard Verilog-2005 (IEEE 1364-2005).
- Każdy plik zaczyna się od `` `default_nettype none `` i kończy `` `default_nettype wire ``.
- W blokach sekwencyjnych wyłącznie przypisania nieblokujące (`<=`), w kombinacyjnych (`always @*`) wyłącznie blokujące (`=`).
- Porty w stylu ANSI, rozmiary liczb zawsze jawne (`8'd0`, nie `0` tam, gdzie liczy się szerokość).

## SystemVerilog

- Standard IEEE 1800-2017; konstrukcje z 1800-2023 tylko z adnotacją.
- RTL: `logic`, `always_ff`, `always_comb`, `enum` dla stanów, `unique case` tam, gdzie warunki się wykluczają.
- Kod syntezowalny musi przechodzić przez Quartus Prime Lite — jego obsługa SystemVeriloga jest niepełna. Konstrukcje, których Lite nie przyjmuje, oznaczamy w tekście i pokazujemy obejście.

## Testbenche

Każdy testbench jest **samosprawdzający** i działa bez interakcji:

1. Sam generuje zegar, reset i pobudzenia.
2. Porównuje wyniki z oczekiwanymi (model referencyjny, tablica wartości albo plik).
3. Na końcu wypisuje dokładnie jedną linię `PASS` albo `FAIL: <powód>` i kończy symulację.
4. Ma ograniczenie czasu (watchdog), żeby zawieszony test nie blokował CI.
5. Zmienia pobudzenia na **opadającym** zboczu zegara (albo z opóźnieniem po zboczu narastającym), a nie w tej samej chwili, w której układ badany próbkuje wejścia. Inaczej wynik zależy od kolejności zdarzeń w symulatorze — ten sam testbench przechodzi w Icarusie, a nie przechodzi w Verilatorze.

Skrypt [tools/run_hdl_tests.py](../tools/run_hdl_tests.py) wyszukuje wszystkie pliki `tb_*` i uruchamia je odpowiednim symulatorem:

| Katalog | Symulator | Polecenie (uproszczone) |
|---------|-----------|-------------------------|
| `hdl/vhdl/` | GHDL | `ghdl -a --std=08 *.vhd && ghdl -r --std=08 tb_x` |
| `hdl/verilog/` | Icarus Verilog | `iverilog -g2005 -o tb tb_x.v *.v && vvp tb` |
| `hdl/sv/` | Verilator 5 | `verilator --binary --timing --top-module tb_x *.sv` |

Lokalnie: `python3 tools/run_hdl_tests.py` (wszystko) albo `python3 tools/run_hdl_tests.py modules/07-kodowanie-pod-synteze` (jeden moduł). W Questa testbenche uruchamiają się bez zmian.

Testbenche UVM (moduł 11) wymagają Questa i nie są uruchamiane w CI — mają własny skrypt `run.do`.

## Projekty na DECA

- W repozytorium nie ma plików `.qpf` ani `.qsf` — projekt tworzy skrypt `utworz_projekt.tcl`:

  ```bash
  cd modules/07-kodowanie-pod-synteze/deca/licznik
  quartus_sh -t utworz_projekt.tcl verilog   # albo vhdl / sv
  quartus_sh --flow compile licznik
  quartus_pgm -c 1 -m jtag -o "p;output_files/licznik.sof"
  ```

- Skrypt projektu ma kilka linii: wywołuje wspólną procedurę `deca_utworz_projekt` z [plytka-deca/deca_projekt.tcl](../plytka-deca/deca_projekt.tcl), podając nazwę projektu, moduły z `hdl/` i potrzebne piny. Procedura wybiera wariant językowy, dołącza pliki SDC i przypisania z [deca_piny.tcl](../plytka-deca/deca_piny.tcl).
- `Makefile` projektu ma dwie linie (`PROJEKT := licznik` i dołączenie [plytka-deca/deca.mk](../plytka-deca/deca.mk)), a daje polecenia `make`, `make JEZYK=vhdl`, `make sram`, `make flash`, `make czas`, `make czysc` ([03.05](../modules/03-przeplyw-projektowy/03.05-praca-skryptowa-tcl-tryb-wsadowy-i-makefile.md)).
- Katalogi `db/`, `incremental_db/`, `output_files/` i pliki generowane są w `.gitignore`.
