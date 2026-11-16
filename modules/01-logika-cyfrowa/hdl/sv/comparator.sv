// Komparator liczb bez znaku: równe, mniejsze, większe.
module comparator #(
    parameter int W = 8
) (
    input  logic [W-1:0] a, b,
    output logic         eq, lt, gt
);
    assign eq = (a == b);
    assign lt = (a <  b);
    assign gt = (a >  b);
endmodule
