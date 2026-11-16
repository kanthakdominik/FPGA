// Ta sama funkcja co addsel_two_adders, opisana jako "multiplekser, potem jeden sumator".
// Gwarantuje jeden sumator niezależnie od tego, czy syntezator dzieli zasoby.
`default_nettype none

module addsel_one_adder #(
    parameter integer W = 16
) (
    input  wire         sel,
    input  wire [W-1:0] a, b, c,
    output wire [W:0]   y
);
    wire [W-1:0] operand = sel ? c : b;
    assign y = a + operand;
endmodule

`default_nettype wire
