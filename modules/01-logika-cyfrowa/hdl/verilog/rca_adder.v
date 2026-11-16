// Sumator z przeniesieniem szeregowym (ripple-carry) zbudowany z W sumatorów pełnych.
`default_nettype none

module rca_adder #(
    parameter integer W = 8
) (
    input  wire [W-1:0] a, b,
    input  wire         cin,
    output wire [W-1:0] s,
    output wire         cout
);
    wire [W:0] c;                        // c[i] = przeniesienie na wejście bitu i
    assign c[0] = cin;

    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : g_fa
            full_adder u_fa (
                .a(a[i]), .b(b[i]), .cin(c[i]), .s(s[i]), .cout(c[i+1])
            );
        end
    endgenerate

    assign cout = c[W];
endmodule

`default_nettype wire
