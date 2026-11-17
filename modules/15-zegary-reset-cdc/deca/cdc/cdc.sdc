# Ograniczenia projektu "cdc" (moduł 15) — dwie domeny zegarowe bez wspólnej fazy.

create_clock -name clk50 -period 20.000  [get_ports {MAX10_CLK1_50}]
create_clock -name clk10 -period 100.000 [get_ports {ADC_CLK_10}]
derive_clock_uncertainty

# Zegary z różnych źródeł: ścieżki między nimi nie są analizowane jak synchroniczne — przechodzą przez
# synchronizatory (sync_bit), handshake i FIFO z wskaźnikami w kodzie Graya.
set_clock_groups -asynchronous -group {clk50} -group {clk10}

# Przyciski i przełączniki: asynchroniczne, za synchronizatorami. Diody bez wymagań.
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to   [get_ports {LED[*]}]

# Wskaźniki w kodzie Graya przechodzą między domenami bit po bicie. Kod Graya gwarantuje poprawność tylko
# wtedy, gdy rozrzut opóźnień bitów jest mniejszy niż okres zegara nadającego — inaczej odbiornik może
# zobaczyć dwa bity zmienione naraz. set_clock_groups wyłącza analizę czasową, ale set_net_delay
# i set_max_skew Quartus stosuje także na takich ścieżkach (tak ograniczane są kolejki dcfifo).
set gray_wr [get_registers {*u_fifo|wr_gray[*]}]
set gray_rd [get_registers {*u_fifo|rd_gray[*]}]
set sync_wr [get_registers {*u_fifo|u_sync_wr|sync_r*}]
set sync_rd [get_registers {*u_fifo|u_sync_rd|sync_r*}]
set_net_delay -max 8.0 -from $gray_wr -to $sync_wr        ;# 0,4 × okres clk50 (nadawca wr_gray)
set_net_delay -max 8.0 -from $gray_rd -to $sync_rd
set_max_skew  -from $gray_wr -to $sync_wr 4.0
set_max_skew  -from $gray_rd -to $sync_rd 4.0

# Dane handshake'u i słowo w pamięci FIFO są stabilne co najmniej 2 takty zegara odbiorcy, zanim zostaną
# przechwycone — wystarczy ograniczyć opóźnienie połączeń, żeby nie przekroczyło okresu clk50.
set_net_delay -max 16.0 -from [get_registers {*u_hs|data_r[*]}] -to [get_registers {*u_hs|dst_data[*]}]
