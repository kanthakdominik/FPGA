// Testbench kodu Graya: wszystkie 256 wartości; model liczy kod Graya arytmetycznie, parzystość — $countones.
`timescale 1ns / 1ps

module tb_gray_codec;
    localparam int W = 8;

    logic [W-1:0] bin_in, gray_out, gray_in, bin_out;
    logic         par;

    gray_codec #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int i = 0; i < 2**W; i++) begin
            bin_in  = W'(i);
            gray_in = W'(i ^ (i >> 1));
            #1;
            if (gray_out != gray_in || int'(bin_out) != i || par != ($countones(bin_in) % 2)) begin
                $display("i=%0d gray=%h bin=%h par=%b", i, gray_out, bin_out, par); errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
