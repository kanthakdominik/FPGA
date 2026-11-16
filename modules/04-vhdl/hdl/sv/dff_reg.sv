// Rejestr W-bitowy bez resetu i zezwolenia — element ścieżki danych.
module dff_reg #(
    parameter int W = 8
) (
    input  logic         clk,
    input  logic [W-1:0] d,
    output logic [W-1:0] q
);
    always_ff @(posedge clk)
        q <= d;
endmodule
