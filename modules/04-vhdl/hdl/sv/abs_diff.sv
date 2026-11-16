// Moduł różnicy |a - b| dla liczb bez znaku — jawne rzutowania typów.
module abs_diff #(
    parameter int W = 8
) (
    input  logic [W-1:0] a, b,                     // liczby bez znaku
    output logic [W-1:0] y,                        // |a - b| zawsze mieści się w W bitach
    output logic         a_lt_b
);
    logic signed [W:0] diff;

    // (W+1)'(a): poszerzenie zerem do W+1 bitów; signed'(...): interpretacja ze znakiem
    assign diff   = signed'((W+1)'(a)) - signed'((W+1)'(b));
    assign a_lt_b = diff[W];
    assign y      = W'(a_lt_b ? -diff : diff);
endmodule
