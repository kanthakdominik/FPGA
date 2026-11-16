// Komparator liczb bez znaku: równe, mniejsze, większe.
`default_nettype none

module comparator #(
    parameter integer W = 8
) (
    input  wire [W-1:0] a, b,
    output wire         eq, lt, gt
);
    assign eq = (a == b);
    assign lt = (a <  b);
    assign gt = (a >  b);
endmodule

`default_nettype wire
