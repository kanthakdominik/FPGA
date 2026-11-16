// Rejestr przesuwny szeregowo-równoległy (deserializator): nowy bit wchodzi na najmłodszą pozycję.
`default_nettype none

module shift_sipo #(
    parameter W = 8
) (
    input  wire         clk,
    input  wire         shift,
    input  wire         sin,
    output wire [W-1:0] dout
);
    reg [W-1:0] sr;

    always @(posedge clk)
        if (shift) sr <= {sr[W-2:0], sin};

    assign dout = sr;
endmodule

`default_nettype wire
