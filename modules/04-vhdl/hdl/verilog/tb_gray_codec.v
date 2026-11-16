// Testbench kodu Graya: wszystkie 256 wartości; model liczy kod Graya i parzystość arytmetycznie.
`default_nettype none
`timescale 1ns / 1ps

module tb_gray_codec;
    localparam integer W = 8;

    reg  [W-1:0] bin_in, gray_in;
    wire [W-1:0] gray_out, bin_out;
    wire         par;

    gray_codec #(.W(W)) dut (.bin_in(bin_in), .gray_out(gray_out), .gray_in(gray_in), .bin_out(bin_out), .par(par));

    integer errors = 0, i, k, ones;

    initial begin
        for (i = 0; i < (1 << W); i = i + 1) begin
            bin_in  = i;
            gray_in = i ^ (i >> 1);
            #1;
            ones = 0;
            for (k = 0; k < W; k = k + 1) ones = ones + ((i >> k) & 1);
            if (gray_out !== (i ^ (i >> 1)) || bin_out !== i || par !== ones % 2) begin
                $display("i=%0d gray=%h bin=%h par=%b", i, gray_out, bin_out, par); errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
