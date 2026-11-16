// Prosta jednostka arytmetyczno-logiczna z kodami operacji jako typem wyliczeniowym.
//   carry: przeniesienie (add), brak pożyczki (sub: a >= b), bit wysunięty (przesunięcia), 0 (pozostałe)
module alu #(
    parameter int W = 8
) (
    input  logic [W-1:0] a, b,
    input  logic [2:0]   op,
    output logic [W-1:0] y,
    output logic         carry,
    output logic         zero
);
    typedef enum logic [2:0] {
        OP_ADD = 3'd0, OP_SUB = 3'd1, OP_AND = 3'd2, OP_OR  = 3'd3,
        OP_XOR = 3'd4, OP_SHL = 3'd5, OP_SHR = 3'd6, OP_PASS = 3'd7
    } op_t;

    always_comb begin
        carry = 1'b0;
        unique case (op_t'(op))
            OP_ADD:  {carry, y} = {1'b0, a} + {1'b0, b};
            OP_SUB:  {carry, y} = {1'b0, a} + {1'b0, ~b} + 1'b1;   // carry = 1: brak pożyczki
            OP_AND:  y = a & b;
            OP_OR:   y = a | b;
            OP_XOR:  y = a ^ b;
            OP_SHL:  {carry, y} = {a, 1'b0};
            OP_SHR:  {y, carry} = {1'b0, a};
            OP_PASS: y = b;
        endcase
    end

    assign zero = (y == '0);
endmodule
