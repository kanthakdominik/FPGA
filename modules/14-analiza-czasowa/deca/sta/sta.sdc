# Ograniczenia czasowe projektu "sta" (moduł 14) — Quartus Timing Analyzer, składnia SDC.
# Zegary (14.03), wyjątki (14.04), wejścia i wyjścia SPI z zegarem przesyłanym (14.06).

# ---------------------------------------------------------------- zegary
# Oscylator 50 MHz na płytce.
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]

# Wyjście PLL: zegar generowany jawnie, z czytelną nazwą (zamiast derive_pll_clocks, które nadaje nazwy
# w rodzaju u_pll|auto_generated|pll1|clk[0]).
create_generated_clock -name clk_sys -source [get_pins -compatibility_mode {*u_pll*|inclk[0]}] \
    -multiply_by 2 [get_pins -compatibility_mode {*u_pll*|clk[0]}]

# Zegar SPI: rejestr sclk_r dzieli clk_sys przez 4 (DIV = 2), a na porcie GPIO0_D[0] jest jego kopia
# opóźniona o ścieżkę wyjściową — to ona taktuje urządzenie zewnętrzne.
create_generated_clock -name sclk_reg -source [get_pins -compatibility_mode {*u_pll*|clk[0]}] \
    -divide_by 4 [get_registers {*u_spi|sclk_r}]
create_generated_clock -name sclk_pin -source [get_registers {*u_spi|sclk_r}] [get_ports {GPIO0_D[0]}]

# Jitter PLL, niepewność oscylatora i przejścia między zegarami — wartości z modeli Quartusa.
derive_clock_uncertainty

# ---------------------------------------------------------------- wyjątki (14.04)
# Przyciski i przełączniki: wejścia asynchroniczne, synchronizatory w projekcie.
set_false_path -from [get_ports {KEY[*] SW[*]}]
# Diody: brak wymagań w skali nanosekund.
set_false_path -to [get_ports {LED[*]}]
# Sygnał locked z PLL steruje asynchronicznym resetem (synchronizator rst_sync) — nie jest ścieżką danych.
set_false_path -through [get_pins -compatibility_mode {*u_pll*|locked}]

# Dzielnik (N = 8): argumenty stałe przez 8 taktów, wynik zapisywany w 8. takcie po ich zapisie.
# Ścieżka dzielnika 16/8 ma w FPGA ok. 50 ns (nextpnr-ecp5, klasa 6: 54 ns) — przy 10 ns potrzeba >= 6 taktów.
set dz_od [get_registers {*u_dziel|a_r[*] *u_dziel|b_r[*]}]
set dz_do [get_registers {*u_dziel|q[*] *u_dziel|r[*]}]
set_multicycle_path -setup -end 8 -from $dz_od -to $dz_do
set_multicycle_path -hold  -end 7 -from $dz_od -to $dz_do

# ---------------------------------------------------------------- SPI (14.06)
# Urządzenie podrzędne (przykładowe wartości z karty katalogowej): t_su = 5 ns, t_h = 5 ns przed/po
# narastającym zboczu SCLK; t_co = 2…10 ns od opadającego zbocza SCLK. Ścieżki na płytce: 0,2…0,5 ns.
set spi_tsu   5.0
set spi_th    5.0
set spi_tco_max 10.0
set spi_tco_min  2.0
set plyta_max 0.5
set plyta_min 0.2

# MOSI i CS_N: wyjścia taktowane clk_sys, próbkowane w urządzeniu narastającym zboczem sclk_pin.
set_output_delay -clock sclk_pin -max [expr {$spi_tsu + $plyta_max}] [get_ports {GPIO0_D[1] GPIO0_D[2]}]
set_output_delay -clock sclk_pin -min [expr {$plyta_min - $spi_th}]  [get_ports {GPIO0_D[1] GPIO0_D[2]}]
# MOSI zmienia się przy opadającym zboczu SCLK (DIV = 2 takty clk_sys przed narastającym) i trzyma
# do następnego opadającego (2 takty po narastającym): setup przesunięty o 2 takty nadawcy, hold o 3.
set_multicycle_path -setup -start 2 -from [get_clocks clk_sys] -to [get_clocks sclk_pin]
set_multicycle_path -hold  -start 3 -from [get_clocks clk_sys] -to [get_clocks sclk_pin]

# MISO: urządzenie zmienia dane po opadającym zboczu SCLK (t_co), FPGA próbkuje je zboczem clk_sys,
# w którym sclk_r przechodzi na 1 — DIV = 2 takty clk_sys po opadającym zboczu.
set_input_delay -clock sclk_pin -clock_fall -max [expr {$spi_tco_max + 2 * $plyta_max}] [get_ports {GPIO0_D[3]}]
set_input_delay -clock sclk_pin -clock_fall -min [expr {$spi_tco_min + 2 * $plyta_min}] [get_ports {GPIO0_D[3]}]
set_multicycle_path -setup -end 2 -from [get_clocks sclk_pin] -to [get_clocks clk_sys]
set_multicycle_path -hold  -end 3 -from [get_clocks sclk_pin] -to [get_clocks clk_sys]
