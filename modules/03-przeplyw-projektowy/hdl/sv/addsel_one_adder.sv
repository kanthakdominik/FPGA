// Ta sama funkcja co addsel_two_adders, opisana jako "multiplekser, potem jeden sumator".
// Gwarantuje jeden sumator niezależnie od tego, czy syntezator dzieli zasoby.
module addsel_one_adder #(
    parameter int W = 16
) (
    input  logic         sel,
    input  logic [W-1:0] a, b, c,
    output logic [W:0]   y
);
    logic [W-1:0] operand;

    assign operand = sel ? c : b;
    assign y       = a + operand;
endmodule
