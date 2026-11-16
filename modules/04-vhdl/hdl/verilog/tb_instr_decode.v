// Testbench dekodera rozkazów: wszystkie 256 kodów, model z porównań zakresów liczb.
`default_nettype none
`timescale 1ns / 1ps

module tb_instr_decode;
    reg  [7:0] instr;
    wire [2:0] cls;
    wire       is_branch;

    instr_decode dut (.instr(instr), .cls(cls), .is_branch(is_branch));

    integer errors = 0, i, e;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            instr = i; #1;
            if      (i >= 128) e = 1;
            else if (i >= 64)  e = 2;
            else if (i >= 32)  e = 3;
            else if (i >= 16)  e = 4;
            else if (i == 0)   e = 0;
            else               e = 7;
            if (cls !== e || is_branch !== (e == 3)) begin
                $display("instr=%b cls=%0d is_branch=%b", instr, cls, is_branch); errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
