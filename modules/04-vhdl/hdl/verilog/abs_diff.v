// Moduł różnicy |a - b| dla liczb bez znaku — jawne przejście na arytmetykę ze znakiem.
`default_nettype none

module abs_diff #(
    parameter integer W = 8
) (
    input  wire [W-1:0] a, b,                      // liczby bez znaku
    output wire [W-1:0] y,                         // |a - b| zawsze mieści się w W bitach
    output wire         a_lt_b
);
    // {1'b0, a}: poszerzenie zerem, potem $signed — bit znaku = 0, wartość bez zmian
    wire signed [W:0] diff = $signed({1'b0, a}) - $signed({1'b0, b});
    wire signed [W:0] mag  = diff[W] ? -diff : diff;

    assign y      = mag[W-1:0];
    assign a_lt_b = diff[W];
endmodule

`default_nettype wire
