// Odbiornik źródłowo-synchroniczny (22.02): rejestr wejściowy DDR taktowany odebranym zegarem rx_clk
// (osobna domena zegarowa); wynik — 2 bity na takt rx_clk. Dalsze przejście do zegara systemowego
// przez FIFO asynchroniczne (15.04).
`default_nettype none

module zs_odbiornik (
    input  wire       rx_clk,
    input  wire       rx_d,
    output wire [1:0] dane                    // dane[1] — bit odebrany pierwszy
);
    ddr_wej u_dane (.clk(rx_clk), .d(rx_d), .q_h(dane[1]), .q_l(dane[0]));
endmodule

`default_nettype wire
