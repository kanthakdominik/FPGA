// Zadanie 2: licznik modulo N z zezwoleniem i wyjściem przeniesienia (do łączenia liczników kaskadowo:
// carry następnego stopnia = en, jak w liczniku sekund i minut). Działa dla dowolnego N >= 2.
`default_nettype none

module mod_counter #(
    parameter integer N = 10,
    parameter integer W = $clog2(N)
) (
    input  wire         clk,
    input  wire         rst,
    input  wire         en,
    output reg  [W-1:0] q = {W{1'b0}},
    output wire         carry
);
    localparam integer LAST = N - 1;
    wire at_last = (q == LAST[W-1:0]);

    always @(posedge clk)
        if (rst)
            q <= {W{1'b0}};
        else if (en)
            q <= at_last ? {W{1'b0}} : q + 1'b1;

    assign carry = en & at_last;    // impuls w takcie przejścia N-1 -> 0
endmodule

`default_nettype wire
