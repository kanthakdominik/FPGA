// Sumator z przeniesieniem szeregowym (ripple-carry) zbudowany z W sumatorów pełnych.
module rca_adder #(
    parameter int W = 8
) (
    input  logic [W-1:0] a, b,
    input  logic         cin,
    output logic [W-1:0] s,
    output logic         cout
);
    logic [W:0] c;                       // c[i] = przeniesienie na wejście bitu i
    assign c[0] = cin;

    for (genvar i = 0; i < W; i++) begin : g_fa
        full_adder u_fa (
            .a(a[i]), .b(b[i]), .cin(c[i]), .s(s[i]), .cout(c[i+1])
        );
    end

    assign cout = c[W];
endmodule
