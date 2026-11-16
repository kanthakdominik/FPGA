// Testbench liczenia jedynek: wszystkie 256 wartości, model z funkcji $countones.
`timescale 1ns / 1ps

module tb_popcount;
    localparam int W = 8;

    logic [W-1:0] d;
    logic [3:0]   count;

    popcount #(.W(W)) dut (.*);

    int errors = 0;

    initial begin
        for (int i = 0; i < 2**W; i++) begin
            d = W'(i); #1;
            if (int'(count) != $countones(d)) begin
                $display("popcount(%0d) = %0d", i, count); errors++;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
