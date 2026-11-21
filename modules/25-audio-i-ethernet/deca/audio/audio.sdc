# Ograniczenia projektu "audio" (moduł 25): 50 MHz na wejściu PLL, logika na 12,5 MHz (MCLK kodeka).
# Sygnały I2S (BCLK = MCLK/4) i I2C są wolne względem zegara — wyjścia i wejścia bez ograniczeń wejścia/wyjścia
# (zapas: dane zmieniane i próbkowane w odstępie ≥ 160 ns od zboczy BCLK, 25.01).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_pll_clocks
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*] SW[*] AUDIO_DOUT_MFP2 AUDIO_SDA_MOSI AUDIO_SCL_SS_n}]
set_false_path -to   [get_ports {LED[*] AUDIO_*}]
