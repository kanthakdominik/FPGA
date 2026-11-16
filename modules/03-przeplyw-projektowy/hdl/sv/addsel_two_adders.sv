// Wybór jednej z dwóch sum: y = a + b albo a + c.
// Opis "dwa sumatory, potem multiplekser" — syntezator może (ale nie musi) zamienić go na jeden sumator.
module addsel_two_adders #(
    parameter int W = 16
) (
    input  logic         sel,
    input  logic [W-1:0] a, b, c,
    output logic [W:0]   y
);
    logic [W:0] sum_ab, sum_ac;

    assign sum_ab = a + b;
    assign sum_ac = a + c;
    assign y      = sel ? sum_ac : sum_ab;
endmodule
