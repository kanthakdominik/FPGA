// Testbench tiny_cpu: dwa programy (ciąg Fibonacciego i odliczanie z JNZ/HALT), losowe step.
// Model: interpreter listy instrukcji napisany w testbenchu (bez automatu i sygnałów sterujących) liczy
// oczekiwane wartości instrukcji OUT; każdy impuls out_valid jest z nimi porównywany.
`timescale 1ns / 1ps

module tb_tiny_cpu;
    localparam logic [127:0] FIB   = 128'hE0E0_E0E0_E0E0_E0E0_D25A_4664_62C0_1100;
    localparam logic [127:0] COUNT = 128'hE0E0_E0E0_E0E0_E0E0_E0E0_C082_45C0_110A;
    localparam int MAXOUT = 20;

    logic       clk = 1'b0, rst = 1'b1, step = 1'b0;
    logic [7:0] out_f, out_c;
    logic       v_f, v_c, halt_f, halt_c;
    logic [3:0] pc_f, pc_c;

    always #5 clk = ~clk;

    tiny_cpu #(.PROG(FIB))   u_fib (.clk, .rst, .step, .out_data(out_f), .out_valid(v_f), .halted(halt_f), .pc_o(pc_f));
    tiny_cpu #(.PROG(COUNT)) u_cnt (.clk, .rst, .step, .out_data(out_c), .out_valid(v_c), .halted(halt_c), .pc_o(pc_c));

    // interpreter: wykonuje program do HALT albo MAXOUT wartości OUT; zwraca wartości OUT i flagę HALT
    function automatic void interp(logic [127:0] prog, ref logic [7:0] outs [$], ref bit stop);
        logic [7:0] rr [4] = '{default: 8'd0};
        int pc = 0;
        stop = 1'b0;
        for (int guard = 0; guard < 1000 && !stop && outs.size() < MAXOUT; guard++) begin
            logic [7:0] ins = prog[8*pc +: 8];
            logic [1:0] d = ins[5:4], s = ins[3:2];
            pc = (pc + 1) % 16;
            case (ins[7:6])
                2'd0: rr[d] = {4'd0, ins[3:0]};
                2'd1: case (ins[1:0])
                          2'd0: rr[d] = rr[d] + rr[s];
                          2'd1: rr[d] = rr[d] - rr[s];
                          2'd2: rr[d] = rr[s];
                          2'd3: rr[d] = rr[d] ^ rr[s];
                      endcase
                2'd2: if (rr[d] != 0) pc = int'(ins[3:0]);
                2'd3: case (d)
                          2'd0: outs.push_back(rr[s]);
                          2'd1: pc = int'(ins[3:0]);
                          2'd2: stop = 1'b1;
                          2'd3: ;
                      endcase
            endcase
        end
    endfunction

    logic [7:0] exp_f [$], exp_c [$];
    bit         stop_f, stop_c;
    int         got_f = 0, got_c = 0, errors = 0;

    initial begin
        interp(FIB, exp_f, stop_f);
        interp(COUNT, exp_c, stop_c);

        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (int n = 0; n < 3000; n++) begin
            step = 1'($urandom);
            @(negedge clk);
            if (v_f && got_f < exp_f.size()) begin
                if (out_f != exp_f[got_f]) begin
                    $display("Fibonacci %0d: %0d, oczekiwano %0d", got_f, out_f, exp_f[got_f]); errors++;
                end
                got_f++;
            end
            if (v_c) begin
                if (got_c >= exp_c.size() || out_c != exp_c[got_c]) begin
                    $display("odliczanie %0d: %0d", got_c, out_c); errors++;
                end
                got_c++;
            end
        end

        if (got_f < exp_f.size() || got_c != exp_c.size() || halt_c != stop_c || halt_f != 1'b0) begin
            $display("Fibonacci %0d/%0d, odliczanie %0d/%0d, halt %b/%b", got_f, exp_f.size(), got_c, exp_c.size(),
                     halt_c, halt_f);
            errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
