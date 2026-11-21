# Ograniczenia projektu "qspi" (moduł 23): 50 MHz; SCLK 12,5 MHz z logiki — dane próbkowane w takcie zbocza SCLK,
# pół okresu SCLK (40 ns) zapasu na drogę w obie strony; ścieżki do pinów bez ograniczeń (zapas sprawdzony
# rachunkiem w 23.03).
create_clock -name clk50 -period 20.000 [get_ports {MAX10_CLK1_50}]
derive_clock_uncertainty
set_false_path -from [get_ports {KEY[*] SW[*] FLASH_DATA[*]}]
set_false_path -to   [get_ports {LED[*] FLASH_*}]
