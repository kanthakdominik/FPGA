// Operatory bitowe, redukcji i konkatenacji na przykładach.
`default_nettype none

module bit_tricks #(
    parameter integer W = 8
) (
    input  wire [W-1:0] x,
    output wire         is_pow2,                   // x jest potęgą dwójki (dokładnie jedna jedynka)
    output wire [W-1:0] lowest,                    // tylko najmłodsza jedynka x
    output wire [W-1:0] rev,                       // bity w odwrotnej kolejności
    output wire         parity,                    // XOR wszystkich bitów
    output wire         all_ones
);
    assign is_pow2  = (|x) && ((x & (x - 1'b1)) == {W{1'b0}});
    assign lowest   = x & (~x + 1'b1);             // x & -x w kodzie U2
    assign parity   = ^x;                          // operator redukcji XOR
    assign all_ones = &x;                          // operator redukcji AND

    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : g_rev
            assign rev[i] = x[W-1-i];
        end
    endgenerate
endmodule

`default_nettype wire
