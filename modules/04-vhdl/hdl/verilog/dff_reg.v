// Rejestr W-bitowy bez resetu i zezwolenia — element ścieżki danych.
`default_nettype none

module dff_reg #(
    parameter integer W = 8
) (
    input  wire         clk,
    input  wire [W-1:0] d,
    output reg  [W-1:0] q
);
    always @(posedge clk)
        q <= d;
endmodule

`default_nettype wire
