// Nadajnik źródłowo-synchroniczny (22.02): 2 bity na takt przez rejestr wyjściowy DDR i zegar przesyłany
// obok danych tym samym rodzajem rejestru (d_h = 1, d_l = 0) — zegar i dane mają to samo opóźnienie
// w blokach I/O, a przesunięcie zegara do środka bitu robi odbiornik (albo PLL nadajnika).
`default_nettype none

module zs_nadajnik (
    input  logic       clk,
    input  logic [1:0] dane,                   // dane[1] wychodzi pierwszy
    output logic       tx_clk,
    output logic       tx_d
);
    ddr_wyj u_zegar (.clk(clk), .d_h(1'b1), .d_l(1'b0), .q(tx_clk));
    ddr_wyj u_dane  (.clk(clk), .d_h(dane[1]), .d_l(dane[0]), .q(tx_d));
endmodule

`default_nettype wire
