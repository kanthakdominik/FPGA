// Mnożarka liczb bez znaku: iloczyn ma 2*W bitów.
module mult #(
    parameter int W = 8
) (
    input  logic [W-1:0]   a, b,
    output logic [2*W-1:0] p
);
    assign p = a * b;
endmodule
