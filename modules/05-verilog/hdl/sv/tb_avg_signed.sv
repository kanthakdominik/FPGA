// Testbench średniej ze znakiem: wszystkie pary liczb 4-bitowych, model floor((a + b) / 2).
`timescale 1ns / 1ps

module tb_avg_signed;
    localparam int W = 4;

    logic signed [W-1:0] a, b, y;

    avg_signed #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int i = -8; i <= 7; i++)
            for (int j = -8; j <= 7; j++) begin
                int e;
                a = W'(i); b = W'(j); #1;
                e = $floor((i + j) / 2.0);              // model na liczbach rzeczywistych
                if (int'(y) != e) begin
                    $display("avg(%0d, %0d) = %0d, oczekiwano %0d", i, j, y, e); errors++;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
