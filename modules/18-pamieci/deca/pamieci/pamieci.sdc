# Ograniczenia projektu "pamieci" (moduł 18): dwa niezależne zegary. Jedynym przejściem między domenami
# jest pamięć dwuportowa ram_sdp (zapis 50 MHz, odczyt 10 MHz) — ścieżki rejestr zapisu -> rejestr odczytu
# przez blok M9K nie mają wspólnej relacji czasowej. Pojedyncze słowo może zostać odczytane w trakcie
# zapisu (stara albo nowa jasność jednej diody przez jeden okres PWM) — dla animacji bez znaczenia,
# dla danych wymagałoby protokołu (ping-pong, FIFO asynchroniczne z 15.05).

create_clock -name clk50 -period 20.000  [get_ports {MAX10_CLK1_50}]
create_clock -name clk10 -period 100.000 [get_ports {ADC_CLK_10}]
derive_clock_uncertainty
set_clock_groups -asynchronous -group {clk50} -group {clk10}

set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]
