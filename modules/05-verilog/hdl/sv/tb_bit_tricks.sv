// Testbench operacji bitowych: wszystkie 256 wartości, model z pętli po bitach.
`timescale 1ns / 1ps

module tb_bit_tricks;
    localparam int W = 8;

    logic [W-1:0] x, lowest, rev;
    logic         is_pow2, parity, all_ones;

    bit_tricks #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int i = 0; i < 2**W; i++) begin
            logic [W-1:0] r, low;
            int ones;
            x = W'(i); #1;
            ones = 0; low = '0;
            for (int k = W - 1; k >= 0; k--) begin
                ones += x[k];
                r[W-1-k] = x[k];
                if (x[k]) low = W'(1) << k;
            end
            if (is_pow2 != (ones == 1) || lowest != low || rev != r ||
                parity != (ones % 2) || all_ones != (ones == W)) begin
                $display("x=%b: pow2=%b lowest=%b rev=%b par=%b all=%b", x, is_pow2, lowest, rev, parity, all_ones);
                errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
