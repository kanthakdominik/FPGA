// Suma N liczb bez znaku w drzewie sumatorów, opcjonalnie z rejestrem po każdym poziomie.
// Szerokość wyniku i opóźnienie wynikają z parametrów: W + log2(N) bitów, LATENCY = PIPELINED ? log2(N) : 0.
module adder_tree #(
    parameter int N         = 8,
    parameter int W         = 8,
    parameter bit PIPELINED = 1'b1
) (
    input  logic                       clk,
    input  logic [N-1:0][W-1:0]        x,
    output logic [W+$clog2(N)-1:0]     sum
);
    localparam int L       = $clog2(N);
    localparam int OW      = W + L;
    localparam int LATENCY = PIPELINED ? L : 0;  // do użycia w module nadrzędnym i testach

    if (N < 2 || (N & (N - 1)) != 0)
        $error("adder_tree: N = %0d nie jest potega dwojki", N);

    logic [OW-1:0] node [2*N-1];               // węzły jak w kopcu: liście N-1 .. 2N-2, korzeń 0

    for (genvar i = 0; i < N; i++) begin : g_leaf
        assign node[N-1+i] = OW'(x[i]);
    end
    for (genvar i = 0; i < N - 1; i++) begin : g_node
        if (PIPELINED) begin : g_reg
            logic [OW-1:0] r;                  // rejestr węzła: jeden proces na zmienną
            always_ff @(posedge clk)
                r <= node[2*i+1] + node[2*i+2];
            assign node[i] = r;
        end else begin : g_comb
            assign node[i] = node[2*i+1] + node[2*i+2];
        end
    end

    assign sum = node[0];
endmodule
