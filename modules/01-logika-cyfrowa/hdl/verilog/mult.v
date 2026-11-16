// Mnożarka liczb bez znaku: iloczyn ma 2*W bitów.
`default_nettype none

module mult #(
    parameter integer W = 8
) (
    input  wire [W-1:0]   a, b,
    output wire [2*W-1:0] p
);
    assign p = a * b;
endmodule

`default_nettype wire
