// Maksimum z N liczb bez znaku — drzewo binarne: log2(N) poziomów porównań. N musi być potęgą dwójki.
// Węzły jak w kopcu: liście node[N-1 .. 2N-2], węzeł i ma dzieci 2i+1 i 2i+2, korzeń node[0].
module max_tree #(
    parameter int N = 8,
    parameter int W = 8
) (
    input  logic [N-1:0][W-1:0] x,
    output logic [W-1:0]        y
);
    if (N < 2 || (N & (N - 1)) != 0) begin : g_check
        $error("max_tree: N = %0d nie jest potega dwojki", N);
    end

    logic [W-1:0] node [2*N-1] /* verilator split_var */;    // bez split_var: pozorna pętla UNOPTFLAT

    for (genvar i = 0; i < N; i++) begin : g_leaf
        assign node[N-1+i] = x[i];
    end
    for (genvar i = 0; i < N - 1; i++) begin : g_node
        assign node[i] = (node[2*i+1] > node[2*i+2]) ? node[2*i+1] : node[2*i+2];
    end

    assign y = node[0];
endmodule
