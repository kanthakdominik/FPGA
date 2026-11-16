// Testbench tiny_cpu: dwa programy (ciąg Fibonacciego i odliczanie z JNZ/HALT), losowe step.
// Model: interpreter listy instrukcji napisany w testbenchu (bez automatu i sygnałów sterujących) liczy
// oczekiwane wartości instrukcji OUT; każdy impuls out_valid jest z nimi porównywany.
`default_nettype none
`timescale 1ns / 1ps

module tb_tiny_cpu;
    localparam [127:0] FIB   = 128'hE0E0_E0E0_E0E0_E0E0_D25A_4664_62C0_1100;
    localparam [127:0] COUNT = 128'hE0E0_E0E0_E0E0_E0E0_E0E0_C082_45C0_110A;
    localparam MAXOUT = 20;

    reg        clk = 1'b0, rst = 1'b1, step = 1'b0;
    wire [7:0] out_f, out_c;
    wire       v_f, v_c, halt_f, halt_c;
    wire [3:0] pc_f, pc_c;

    always #5 clk = ~clk;

    tiny_cpu #(.PROG(FIB))   u_fib (.clk(clk), .rst(rst), .step(step), .out_data(out_f), .out_valid(v_f),
                                    .halted(halt_f), .pc_o(pc_f));
    tiny_cpu #(.PROG(COUNT)) u_cnt (.clk(clk), .rst(rst), .step(step), .out_data(out_c), .out_valid(v_c),
                                    .halted(halt_c), .pc_o(pc_c));

    reg [7:0] exp_f [0:MAXOUT-1], exp_c [0:MAXOUT-1];
    integer   nexp_f, nexp_c, got_f = 0, got_c = 0, errors = 0, n, seed = 61;
    reg       halt_exp_c;

    // interpreter: wykonuje program do HALT albo MAXOUT wartości OUT
    reg [7:0] rr [0:3];
    reg [7:0] ins, outs [0:MAXOUT-1];
    integer   pc, nout, guard;
    reg       stop;
    task interp;
        input [127:0] prog;
        begin
            pc = 0; nout = 0; stop = 1'b0; guard = 0;
            rr[0] = 0; rr[1] = 0; rr[2] = 0; rr[3] = 0;
            while (!stop && nout < MAXOUT && guard < 1000) begin
                ins = prog[8*pc +: 8];
                pc  = (pc + 1) % 16;
                guard = guard + 1;
                case (ins[7:6])
                    2'd0: rr[ins[5:4]] = {4'd0, ins[3:0]};
                    2'd1: case (ins[1:0])
                              2'd0: rr[ins[5:4]] = rr[ins[5:4]] + rr[ins[3:2]];
                              2'd1: rr[ins[5:4]] = rr[ins[5:4]] - rr[ins[3:2]];
                              2'd2: rr[ins[5:4]] = rr[ins[3:2]];
                              2'd3: rr[ins[5:4]] = rr[ins[5:4]] ^ rr[ins[3:2]];
                          endcase
                    2'd2: if (rr[ins[5:4]] != 0) pc = ins[3:0];
                    2'd3: case (ins[5:4])
                              2'd0: begin outs[nout] = rr[ins[3:2]]; nout = nout + 1; end
                              2'd1: pc = ins[3:0];
                              2'd2: stop = 1'b1;
                              default: ;
                          endcase
                endcase
            end
        end
    endtask

    initial begin
        interp(FIB);   nexp_f = nout; for (n = 0; n < nout; n = n + 1) exp_f[n] = outs[n];
        interp(COUNT); nexp_c = nout; for (n = 0; n < nout; n = n + 1) exp_c[n] = outs[n];
        halt_exp_c = stop;

        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 0; n < 3000; n = n + 1) begin
            step = $random(seed) & 1;
            @(negedge clk);
            if (v_f && got_f < nexp_f) begin
                if (out_f !== exp_f[got_f]) begin
                    $display("Fibonacci %0d: %0d, oczekiwano %0d", got_f, out_f, exp_f[got_f]); errors = errors + 1;
                end
                got_f = got_f + 1;
            end
            if (v_c) begin
                if (got_c >= nexp_c || out_c !== exp_c[got_c]) begin
                    $display("odliczanie %0d: %0d, oczekiwano %0d", got_c, out_c, exp_c[got_c]); errors = errors + 1;
                end
                got_c = got_c + 1;
            end
        end

        if (got_f < nexp_f || got_c != nexp_c || halt_c !== halt_exp_c || halt_f !== 1'b0) begin
            $display("Fibonacci %0d/%0d, odliczanie %0d/%0d, halt %b/%b", got_f, nexp_f, got_c, nexp_c, halt_c, halt_f);
            errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
