// Rejestr przesuwny z liniowym sprzężeniem zwrotnym (LFSR) w postaci Galois, przesuw w prawo.
// Bit po bicie, przypisaniami nieblokującymi w pętli — kolejność iteracji nie ma znaczenia.
`default_nettype none

module lfsr #(
    parameter integer   W    = 16,
    parameter [W-1:0]   TAPS = 16'hB400,           // x^16 + x^14 + x^13 + x^11 + 1 (maksymalny okres)
    parameter [W-1:0]   SEED = 1                   // stan po resecie, różny od zera
) (
    input  wire         clk,
    input  wire         rst,                       // synchroniczny: ładuje SEED
    input  wire         en,
    output reg  [W-1:0] q
);
    integer i;

    always @(posedge clk) begin
        if (rst)
            q <= SEED;
        else if (en) begin
            for (i = 0; i < W - 1; i = i + 1)
                q[i] <= q[i+1] ^ (TAPS[i] & q[0]); // prawa strona: wartości sprzed zbocza
            q[W-1] <= TAPS[W-1] & q[0];
        end
    end
endmodule

`default_nettype wire
