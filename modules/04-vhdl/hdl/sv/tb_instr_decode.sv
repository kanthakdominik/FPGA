// Testbench dekodera rozkazów: wszystkie 256 kodów, model z porównań zakresów liczb.
`timescale 1ns / 1ps

module tb_instr_decode;
    logic [7:0] instr;
    logic [2:0] cls;
    logic       is_branch;

    instr_decode dut (.*);

    int errors = 0;

    initial begin
        for (int i = 0; i < 256; i++) begin
            int e;
            instr = 8'(i); #1;
            if      (i >= 128) e = 1;
            else if (i >= 64)  e = 2;
            else if (i >= 32)  e = 3;
            else if (i >= 16)  e = 4;
            else if (i == 0)   e = 0;
            else               e = 7;
            if (int'(cls) != e || is_branch != (e == 3)) begin
                $display("instr=%b cls=%0d is_branch=%b", instr, cls, is_branch); errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
