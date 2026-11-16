// Testbench |a - b|: wszystkie pary liczb 4-bitowych bez znaku.
`timescale 1ns / 1ps

module tb_abs_diff;
    localparam int W = 4;

    logic [W-1:0] a, b, y;
    logic         a_lt_b;

    abs_diff #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int i = 0; i < 2**W; i++)
            for (int j = 0; j < 2**W; j++) begin
                a = W'(i); b = W'(j); #1;
                if (int'(y) != (i > j ? i - j : j - i) || a_lt_b != (i < j)) begin
                    $display("|%0d - %0d| = %0d", i, j, y); errors++;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
