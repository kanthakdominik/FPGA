// Testbench sumatora z nasyceniem: wszystkie pary liczb 4-bitowych ze znakiem.
`timescale 1ns / 1ps

module tb_sat_add;
    localparam int W = 4;

    logic signed [W-1:0] a, b, y;
    logic                sat;

    sat_add #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int i = -8; i <= 7; i++)
            for (int j = -8; j <= 7; j++) begin
                int s, e;
                a = W'(i); b = W'(j); #1;
                s = i + j;
                e = (s > 7) ? 7 : (s < -8) ? -8 : s;
                if (int'(y) != e || sat != (s != e)) begin
                    $display("%0d + %0d = %0d sat=%b", i, j, y, sat); errors++;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
