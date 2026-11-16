// Dekoder rozkazów z wartościami obojętnymi (casez: ? = dowolny bit).
//   1xxx_xxxx LOAD (1), 01xx_xxxx ALU (2), 001x_xxxx BRANCH (3), 0001_xxxx MOVE (4),
//   0000_0000 NOP (0), pozostałe 0000_xxxx — ILLEGAL (7)
`default_nettype none

module instr_decode (
    input  wire [7:0] instr,
    output reg  [2:0] cls,
    output wire       is_branch
);
    always @* begin
        casez (instr)
            8'b1???????: cls = 3'd1;
            8'b01??????: cls = 3'd2;
            8'b001?????: cls = 3'd3;
            8'b0001????: cls = 3'd4;
            8'b00000000: cls = 3'd0;
            default:     cls = 3'd7;
        endcase
    end

    assign is_branch = (instr[7:5] == 3'b001);
endmodule

`default_nettype wire
