// Dekoder instrukcji RV32I (27.07): pola rejestrów, stała natychmiastowa (I, S, B, U, J) i sygnały sterujące.
// FENCE, ECALL i EBREAK wykonują się jak NOP; nieznany kod -> nielegalna = 1 i również NOP.
`default_nettype none

module rv_dekoder (
    input  logic [31:0] ins,
    output logic [4:0]  rd,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [2:0]  f3,
    output logic  [31:0] imm,
    output logic  [3:0]  alu_op,
    output logic         a_pc,              // argument A = PC (AUIPC)
    output logic         a_zero,            // argument A = 0 (LUI)
    output logic         b_imm,             // argument B = stała
    output logic         zapis_rd,
    output logic         odczyt,
    output logic         zapis,
    output logic         galaz,
    output logic         jal,
    output logic         jalr,
    output logic         uzywa_rs1,
    output logic         uzywa_rs2,
    output logic         nielegalna
);
    assign rd  = ins[11:7];
    assign rs1 = ins[19:15];
    assign rs2 = ins[24:20];
    assign f3  = ins[14:12];
    logic [6:0] opc;
    assign opc = ins[6:0];

    logic [31:0] imm_i;
    assign imm_i = {{21{ins[31]}}, ins[30:20]};
    logic [31:0] imm_s;
    assign imm_s = {{21{ins[31]}}, ins[30:25], ins[11:7]};
    logic [31:0] imm_b;
    assign imm_b = {{20{ins[31]}}, ins[7], ins[30:25], ins[11:8], 1'b0};
    logic [31:0] imm_u;
    assign imm_u = {ins[31:12], 12'd0};
    logic [31:0] imm_j;
    assign imm_j = {{12{ins[31]}}, ins[19:12], ins[20], ins[30:21], 1'b0};

    always_comb begin
        imm = imm_i; alu_op = 4'd0; a_pc = 1'b0; a_zero = 1'b0; b_imm = 1'b0;
        zapis_rd = 1'b0; odczyt = 1'b0; zapis = 1'b0; galaz = 1'b0; jal = 1'b0; jalr = 1'b0;
        uzywa_rs1 = 1'b0; uzywa_rs2 = 1'b0; nielegalna = 1'b0;
        case (opc)
            7'b0110111: begin imm = imm_u; a_zero = 1'b1; b_imm = 1'b1; zapis_rd = 1'b1; end            // LUI
            7'b0010111: begin imm = imm_u; a_pc = 1'b1; b_imm = 1'b1; zapis_rd = 1'b1; end              // AUIPC
            7'b1101111: begin imm = imm_j; jal = 1'b1; zapis_rd = 1'b1; end                             // JAL
            7'b1100111:                                                                                 // JALR
                if (f3 == 3'd0) begin
                    b_imm = 1'b1; jalr = 1'b1; zapis_rd = 1'b1; uzywa_rs1 = 1'b1;
                end else nielegalna = 1'b1;
            7'b1100011:                                                                                 // BRANCH
                if (f3 != 3'd2 && f3 != 3'd3) begin
                    imm = imm_b; galaz = 1'b1; uzywa_rs1 = 1'b1; uzywa_rs2 = 1'b1;
                end else nielegalna = 1'b1;
            7'b0000011:                                                                                 // LOAD
                if (f3 != 3'd3 && f3 != 3'd6 && f3 != 3'd7) begin
                    b_imm = 1'b1; odczyt = 1'b1; zapis_rd = 1'b1; uzywa_rs1 = 1'b1;
                end else nielegalna = 1'b1;
            7'b0100011:                                                                                 // STORE
                if (f3 <= 3'd2) begin
                    imm = imm_s; b_imm = 1'b1; zapis = 1'b1; uzywa_rs1 = 1'b1; uzywa_rs2 = 1'b1;
                end else nielegalna = 1'b1;
            7'b0010011: begin                                                                           // OP-IMM
                b_imm = 1'b1; zapis_rd = 1'b1; uzywa_rs1 = 1'b1;
                alu_op = {f3 == 3'd5 && ins[30], f3};
            end
            7'b0110011: begin                                                                           // OP
                zapis_rd = 1'b1; uzywa_rs1 = 1'b1; uzywa_rs2 = 1'b1;
                alu_op = {ins[30], f3};
            end
            7'b0001111, 7'b1110011: ;                                                                   // FENCE, SYSTEM
            default: nielegalna = 1'b1;
        endcase
    end
endmodule

`default_nettype wire
