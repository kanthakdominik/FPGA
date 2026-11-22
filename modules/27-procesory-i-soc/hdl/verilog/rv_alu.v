// ALU rdzeni RV32I (27.07): op = {bit 30 instrukcji dla SUB/SRA/SRAI, funct3}. Przesunięcia biorą 5 młodszych
// bitów drugiego argumentu. Kombinacyjna.
`default_nettype none

module rv_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  op,
    output reg  [31:0] y
);
    always @(*)
        case (op[2:0])
            3'd0:    y = op[3] ? a - b : a + b;
            3'd1:    y = a << b[4:0];
            3'd2:    y = {31'd0, $signed(a) < $signed(b)};
            3'd3:    y = {31'd0, a < b};
            3'd4:    y = a ^ b;
            3'd5:    y = op[3] ? $unsigned($signed(a) >>> b[4:0]) : a >> b[4:0];
            3'd6:    y = a | b;
            default: y = a & b;
        endcase
endmodule

`default_nettype wire
