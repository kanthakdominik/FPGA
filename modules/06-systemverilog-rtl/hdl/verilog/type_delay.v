// Linia opóźniająca: Verilog nie ma parametrów typu, więc parametrem jest szerokość W.
// Struktura (np. piksel RGB) musi być spłaszczona do wektora.
`default_nettype none

module type_delay #(
    parameter integer W     = 8,
    parameter integer DEPTH = 2                    // co najmniej 1
) (
    input  wire         clk,
    input  wire [W-1:0] d,
    output wire [W-1:0] q
);
    reg [DEPTH*W-1:0] stage;                       // DEPTH etapów spłaszczonych w jeden wektor

    generate
        if (DEPTH == 1) begin : g_one
            always @(posedge clk) stage <= d;
        end else begin : g_many
            always @(posedge clk) stage <= {stage[(DEPTH-1)*W-1:0], d};
        end
    endgenerate

    assign q = stage[DEPTH*W-1 -: W];              // najstarszy etap
endmodule

`default_nettype wire
