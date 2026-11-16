// Maksimum z N liczb bez znaku — drzewo binarne: log2(N) poziomów porównań. N musi być potęgą dwójki.
// Węzły jak w kopcu: liście node[N-1 .. 2N-2], węzeł i ma dzieci 2i+1 i 2i+2, korzeń node[0].
`default_nettype none

module max_tree #(
    parameter N = 8,
    parameter W = 8
) (
    input  wire [N*W-1:0] x,
    output wire [W-1:0]   y
);
    wire [W-1:0] node [0:2*N-2];

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_leaf
            assign node[N-1+i] = x[i*W +: W];
        end
        for (i = 0; i < N - 1; i = i + 1) begin : g_node
            assign node[i] = (node[2*i+1] > node[2*i+2]) ? node[2*i+1] : node[2*i+2];
        end
    endgenerate

    assign y = node[0];
endmodule

`default_nettype wire
