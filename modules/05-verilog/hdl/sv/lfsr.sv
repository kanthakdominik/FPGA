// LFSR w postaci Galois, przesuw w prawo; przypisania nieblokujące w pętli.
module lfsr #(
    parameter int           W    = 16,
    parameter logic [W-1:0] TAPS = 16'hB400,       // x^16 + x^14 + x^13 + x^11 + 1
    parameter logic [W-1:0] SEED = 1
) (
    input  logic         clk,
    input  logic         rst,
    input  logic         en,
    output logic [W-1:0] q
);
    always_ff @(posedge clk) begin
        if (rst)
            q <= SEED;
        else if (en) begin
            for (int i = 0; i < W - 1; i++)
                q[i] <= q[i+1] ^ (TAPS[i] & q[0]);
            q[W-1] <= TAPS[W-1] & q[0];
        end
    end
endmodule
