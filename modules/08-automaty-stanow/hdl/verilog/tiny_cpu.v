// Mały procesor sekwencyjny (FSMD): 4 rejestry 8-bitowe, program 16 instrukcji w parametrze PROG.
// Sterowanie: automat FETCH -> EXEC -> FETCH … (HALT), krok tylko przy step = 1.
// Ścieżka danych: rejestry R0..R3, licznik rozkazów pc, rejestr instrukcji ir, ALU, rejestr wyjściowy out_data.
//
// Instrukcja 8-bitowa ir[7:6] = kod:
//   00 LDI rd, imm4      rd = imm                   [5:4] rd, [3:0] imm
//   01 ALU rd, rs, fn    fn: 00 ADD, 01 SUB, 10 MOV (rd = rs), 11 XOR    [5:4] rd, [3:2] rs, [1:0] fn
//   10 JNZ rd, addr      jeśli rd != 0: pc = addr   [5:4] rd, [3:0] addr
//   11 SYS               [5:4]: 00 OUT rs ([3:2]), 01 JMP addr ([3:0]), 10 HALT, 11 NOP
`default_nettype none

module tiny_cpu #(
    // instrukcja pod adresem i: PROG[8*i +: 8]; domyślnie ciąg Fibonacciego (OUT R0 w pętli)
    parameter [127:0] PROG = 128'hE0E0_E0E0_E0E0_E0E0_D25A_4664_62C0_1100
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       step,                    // zezwolenie: jeden krok automatu
    output reg  [7:0] out_data = 8'd0,
    output reg        out_valid = 1'b0,        // impuls przy wykonaniu OUT
    output wire       halted,
    output wire [3:0] pc_o
);
    localparam [1:0] ST_FETCH = 2'd0, ST_EXEC = 2'd1, ST_HALT = 2'd2;
    localparam [1:0] OP_LDI = 2'd0, OP_ALU = 2'd1, OP_JNZ = 2'd2, OP_SYS = 2'd3;

    // --- ścieżka danych: rejestry
    reg [1:0] state = ST_FETCH, state_next;
    reg [3:0] pc = 4'd0;
    reg [7:0] ir = 8'd0;
    reg [7:0] r [0:3];

    wire [1:0] op  = ir[7:6];
    wire [1:0] rd  = ir[5:4];
    wire [1:0] rs  = ir[3:2];
    wire [1:0] fn  = ir[1:0];
    wire [3:0] imm = ir[3:0];
    wire [7:0] rd_val = r[rd];
    wire [7:0] rs_val = r[rs];

    // --- ścieżka danych: ALU (kombinacyjnie)
    reg [7:0] wdata;
    always @* begin
        if (op == OP_LDI)
            wdata = {4'h0, imm};
        else
            case (fn)
                2'd0:    wdata = rd_val + rs_val;
                2'd1:    wdata = rd_val - rs_val;
                2'd2:    wdata = rs_val;
                default: wdata = rd_val ^ rs_val;
            endcase
    end

    // --- sterowanie: automat i sygnały sterujące ścieżką danych
    reg ir_load, pc_inc, pc_load, rf_we, out_load;
    always @* begin
        ir_load    = 1'b0;
        pc_inc     = 1'b0;
        pc_load    = 1'b0;
        rf_we      = 1'b0;
        out_load   = 1'b0;
        state_next = state;
        case (state)
            ST_FETCH:
                if (step) begin
                    ir_load    = 1'b1;
                    pc_inc     = 1'b1;
                    state_next = ST_EXEC;
                end
            ST_EXEC:
                if (step) begin
                    state_next = ST_FETCH;
                    case (op)
                        OP_LDI, OP_ALU: rf_we   = 1'b1;
                        OP_JNZ:         pc_load = (rd_val != 8'd0);
                        OP_SYS:
                            case (rd)
                                2'd0:    out_load   = 1'b1;        // OUT
                                2'd1:    pc_load    = 1'b1;        // JMP
                                2'd2:    state_next = ST_HALT;     // HALT
                                default: ;                         // NOP
                            endcase
                    endcase
                end
            ST_HALT: ;
            default: state_next = ST_FETCH;
        endcase
    end

    // --- ścieżka danych: zapis rejestrów
    always @(posedge clk) begin
        out_valid <= out_load;
        if (ir_load)  ir    <= PROG[{pc, 3'b000} +: 8];
        if (rf_we)    r[rd] <= wdata;
        if (out_load) out_data <= rs_val;
        if (rst) begin
            state <= ST_FETCH;
            pc    <= 4'd0;
        end else begin
            state <= state_next;
            if (pc_load)     pc <= imm;
            else if (pc_inc) pc <= pc + 4'd1;
        end
    end

    assign halted = (state == ST_HALT);
    assign pc_o   = pc;
endmodule

`default_nettype wire
