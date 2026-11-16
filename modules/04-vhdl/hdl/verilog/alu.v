// Prosta jednostka arytmetyczno-logiczna.
//   op: 000 a+b, 001 a-b, 010 a&b, 011 a|b, 100 a^b, 101 a<<1, 110 a>>1, 111 b
//   carry: przeniesienie (add), brak pożyczki (sub: a >= b), bit wysunięty (przesunięcia), 0 (pozostałe)
`default_nettype none

module alu #(
    parameter integer W = 8
) (
    input  wire [W-1:0] a, b,
    input  wire [2:0]   op,
    output reg  [W-1:0] y,
    output reg          carry,
    output wire         zero
);
    always @* begin
        carry = 1'b0;
        case (op)
            3'd0: {carry, y} = a + b;
            // a - b = a + ~b + 1; konkatenacje mają własną szerokość, więc ~b jest liczone na W bitach
            3'd1: {carry, y} = {1'b0, a} + {1'b0, ~b} + 1'b1;   // carry = 1: brak pożyczki
            3'd2: y = a & b;
            3'd3: y = a | b;
            3'd4: y = a ^ b;
            3'd5: {carry, y} = {a, 1'b0};
            3'd6: {y, carry} = {1'b0, a};
            default: y = b;
        endcase
    end

    assign zero = (y == {W{1'b0}});
endmodule

`default_nettype wire
