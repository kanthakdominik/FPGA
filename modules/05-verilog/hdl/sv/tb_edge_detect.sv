// Testbench detektora zboczy: sekwencja pseudolosowa, porównanie z poprzednią wartością wejścia.
`timescale 1ns / 1ps

module tb_edge_detect;
    localparam logic [0:31] SEQ = 32'b0110_1110_0010_1101_1100_0101_0011_1010;

    logic clk = 1'b0, d = 1'b0, prev = 1'b0;
    logic rise, fall, any;

    always #5 clk = ~clk;

    edge_detect dut (.*);

    int errors = 0, n_rise = 0;

    initial begin
        @(negedge clk);
        for (int k = 0; k < 32; k++) begin
            d = SEQ[k];
            #1;
            if (rise != (d & ~prev) || fall != (~d & prev) || any != (d ^ prev)) begin
                $display("takt %0d: d=%b prev=%b rise=%b fall=%b any=%b", k, d, prev, rise, fall, any);
                errors++;
            end
            n_rise += rise;
            prev = d;
            @(negedge clk);
        end
        if (n_rise == 0) begin
            $display("brak zboczy w tescie"); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
