// Linia opóźniająca: dout = wartość din sprzed DEPTH taktów z ce = 1.
// Bez resetu i bez odczytu pośrednich odczepów — syntezator może ją zbudować w pamięci RAM.
`default_nettype none

module delay_line #(
    parameter W     = 8,
    parameter DEPTH = 16
) (
    input  wire         clk,
    input  wire         ce,
    input  wire [W-1:0] din,
    output wire [W-1:0] dout
);
    reg [W-1:0] sr [0:DEPTH-1];
    integer i;

    always @(posedge clk)
        if (ce) begin
            sr[0] <= din;
            for (i = 1; i < DEPTH; i = i + 1)
                sr[i] <= sr[i-1];
        end

    assign dout = sr[DEPTH-1];
endmodule

`default_nettype wire
