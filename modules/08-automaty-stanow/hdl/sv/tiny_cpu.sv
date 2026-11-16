// Mały procesor sekwencyjny (FSMD): 4 rejestry 8-bitowe, program 16 instrukcji w parametrze PROG.
// Sterowanie: automat FETCH -> EXEC -> FETCH … (HALT), krok tylko przy step = 1.
// Ścieżka danych: rejestry R0..R3, licznik rozkazów pc, rejestr instrukcji ir, ALU, rejestr wyjściowy out_data.
//
// Instrukcja 8-bitowa ir[7:6] = kod:
//   00 LDI rd, imm4      rd = imm                   [5:4] rd, [3:0] imm
//   01 ALU rd, rs, fn    fn: 00 ADD, 01 SUB, 10 MOV (rd = rs), 11 XOR    [5:4] rd, [3:2] rs, [1:0] fn
//   10 JNZ rd, addr      jeśli rd != 0: pc = addr   [5:4] rd, [3:0] addr
//   11 SYS               [5:4]: 00 OUT rs ([3:2]), 01 JMP addr ([3:0]), 10 HALT, 11 NOP
module tiny_cpu #(
    // instrukcja pod adresem i: PROG[i]; domyślnie ciąg Fibonacciego (OUT R0 w pętli)
    parameter logic [15:0][7:0] PROG = 128'hE0E0_E0E0_E0E0_E0E0_D25A_4664_62C0_1100
) (
    input  logic       clk,
    input  logic       rst,
    input  logic       step,                   // zezwolenie: jeden krok automatu
    output logic [7:0] out_data = '0,
    output logic       out_valid = 1'b0,       // impuls przy wykonaniu OUT
    output logic       halted,
    output logic [3:0] pc_o
);
    typedef enum logic [1:0] {ST_FETCH, ST_EXEC, ST_HALT} state_t;
    typedef enum logic [1:0] {OP_LDI, OP_ALU, OP_JNZ, OP_SYS} op_t;

    // --- ścieżka danych: rejestry
    state_t     state = ST_FETCH, state_next;
    logic [3:0] pc = '0;
    logic [7:0] ir = '0;
    logic [7:0] r [4];

    op_t        op;
    logic [1:0] rd, rs, fn;
    logic [3:0] imm;
    logic [7:0] rd_val, rs_val, wdata;

    assign op     = op_t'(ir[7:6]);
    assign rd     = ir[5:4];
    assign rs     = ir[3:2];
    assign fn     = ir[1:0];
    assign imm    = ir[3:0];
    assign rd_val = r[rd];
    assign rs_val = r[rs];

    // --- ścieżka danych: ALU
    always_comb begin
        if (op == OP_LDI)
            wdata = {4'h0, imm};
        else
            unique case (fn)
                2'd0: wdata = rd_val + rs_val;
                2'd1: wdata = rd_val - rs_val;
                2'd2: wdata = rs_val;
                2'd3: wdata = rd_val ^ rs_val;
            endcase
    end

    // --- sterowanie: automat i sygnały sterujące ścieżką danych
    logic ir_load, pc_inc, pc_load, rf_we, out_load;
    always_comb begin
        ir_load    = 1'b0;
        pc_inc     = 1'b0;
        pc_load    = 1'b0;
        rf_we      = 1'b0;
        out_load   = 1'b0;
        state_next = state;
        unique case (state)
            ST_FETCH:
                if (step) begin
                    ir_load    = 1'b1;
                    pc_inc     = 1'b1;
                    state_next = ST_EXEC;
                end
            ST_EXEC:
                if (step) begin
                    state_next = ST_FETCH;
                    unique case (op)
                        OP_LDI, OP_ALU: rf_we   = 1'b1;
                        OP_JNZ:         pc_load = (rd_val != 8'd0);
                        OP_SYS:
                            unique case (rd)
                                2'd0: out_load   = 1'b1;           // OUT
                                2'd1: pc_load    = 1'b1;           // JMP
                                2'd2: state_next = ST_HALT;        // HALT
                                2'd3: ;                            // NOP
                            endcase
                    endcase
                end
            ST_HALT: ;
            default: state_next = ST_FETCH;
        endcase
    end

    // --- ścieżka danych: zapis rejestrów
    always_ff @(posedge clk) begin
        out_valid <= out_load;
        if (ir_load)  ir    <= PROG[pc];
        if (rf_we)    r[rd] <= wdata;
        if (out_load) out_data <= rs_val;
        if (rst) begin
            state <= ST_FETCH;
            pc    <= '0;
        end else begin
            state <= state_next;
            if (pc_load)     pc <= imm;
            else if (pc_inc) pc <= pc + 4'd1;
        end
    end

    assign halted = (state == ST_HALT);
    assign pc_o   = pc;
endmodule
