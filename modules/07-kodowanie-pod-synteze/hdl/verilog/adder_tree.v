// Suma N liczb bez znaku w drzewie sumatorów, opcjonalnie z rejestrem po każdym poziomie.
// Szerokość wyniku i opóźnienie wynikają z parametrów: W + log2(N) bitów, LATENCY = PIPELINED ? log2(N) : 0.
// N musi być potęgą dwójki (co najmniej 2).
`default_nettype none

module adder_tree #(
    parameter N         = 8,
    parameter W         = 8,
    parameter PIPELINED = 1
) (
    input  wire                     clk,
    input  wire [N*W-1:0]           x,
    output wire [W+$clog2(N)-1:0]   sum
);
    localparam L  = $clog2(N);
    localparam OW = W + L;

    wire [OW-1:0] node [0:2*N-2] /* verilator split_var */;  // węzły jak w kopcu: liście N-1 .. 2N-2, korzeń 0

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_leaf
            assign node[N-1+i] = {{L{1'b0}}, x[i*W +: W]};
        end
        for (i = 0; i < N - 1; i = i + 1) begin : g_node
            if (PIPELINED != 0) begin : g_reg
                reg [OW-1:0] r;
                always @(posedge clk)
                    r <= node[2*i+1] + node[2*i+2];
                assign node[i] = r;
            end else begin : g_comb
                assign node[i] = node[2*i+1] + node[2*i+2];
            end
        end
    endgenerate

    assign sum = node[0];
endmodule

`default_nettype wire
