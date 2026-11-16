// Wybór jednej z dwóch sum: y = a + b albo a + c.
// Opis "dwa sumatory, potem multiplekser" — syntezator może (ale nie musi) zamienić go na jeden sumator.
`default_nettype none

module addsel_two_adders #(
    parameter integer W = 16
) (
    input  wire         sel,
    input  wire [W-1:0] a, b, c,
    output wire [W:0]   y
);
    wire [W:0] sum_ab = a + b;
    wire [W:0] sum_ac = a + c;
    assign y = sel ? sum_ac : sum_ab;
endmodule

`default_nettype wire
