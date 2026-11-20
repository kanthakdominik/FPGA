// Przeliczenie kodu termodiody (kanał 17 ADC MAX 10) na °C (20.06): tablica 512 słów z pliku tsd_temp.hex
// (gen_tsd.py, z tabeli w MAX 10 ADC User Guide), adres = kod − 3431. Kody spoza zakresu tablicy:
// 125 °C (poniżej) albo −40 °C (powyżej). Odczyt synchroniczny — wynik takt po kodzie.
`default_nettype none

module tsd_temperatura #(
    parameter PLIK = "tsd_temp.hex"
) (
    input  wire        clk,
    input  wire [11:0] kod,
    output reg  [7:0]  temp_c                         // U2, °C
);
    reg  [7:0]  tab [0:511];
    initial $readmemh(PLIK, tab);

    wire [12:0] przes = {1'b0, kod} - 13'd3431;
    always @(posedge clk)
        if (przes[12])            temp_c <= 8'd125;          // kod < 3431: powyżej 125 °C
        else if (przes[11:9] != 0) temp_c <= 8'hD8;          // kod >= 3943: poniżej −40 °C
        else                      temp_c <= tab[przes[8:0]];
endmodule

`default_nettype wire
