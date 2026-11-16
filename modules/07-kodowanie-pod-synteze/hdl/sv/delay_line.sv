// Linia opóźniająca: dout = wartość din sprzed DEPTH taktów z ce = 1.
// Bez resetu i bez odczytu pośrednich odczepów — syntezator może ją zbudować w pamięci RAM.
module delay_line #(
    parameter int W     = 8,
    parameter int DEPTH = 16
) (
    input  logic         clk,
    input  logic         ce,
    input  logic [W-1:0] din,
    output logic [W-1:0] dout
);
    logic [W-1:0] sr [DEPTH];

    always_ff @(posedge clk)
        if (ce) begin
            sr[0] <= din;
            for (int i = 1; i < DEPTH; i++)
                sr[i] <= sr[i-1];
        end

    assign dout = sr[DEPTH-1];
endmodule
