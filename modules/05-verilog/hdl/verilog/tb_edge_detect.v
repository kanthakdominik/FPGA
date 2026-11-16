// Testbench detektora zboczy: sekwencja pseudolosowa, w każdym takcie porównanie z poprzednią wartością wejścia.
`default_nettype none
`timescale 1ns / 1ps

module tb_edge_detect;
    localparam [0:31] SEQ = 32'b0110_1110_0010_1101_1100_0101_0011_1010;

    reg  clk = 1'b0;
    reg  d   = 1'b0;
    wire rise, fall, any;
    reg  prev = 1'b0;

    always #5 clk = ~clk;

    edge_detect dut (.clk(clk), .d(d), .rise(rise), .fall(fall), .any(any));

    integer errors = 0, k, n_rise = 0;

    initial begin
        @(negedge clk);
        for (k = 0; k < 32; k = k + 1) begin
            d = SEQ[k];                            // nowa wartość, d_q = poprzednia (z zbocza)
            #1;
            if (rise !== (d & ~prev) || fall !== (~d & prev) || any !== (d ^ prev)) begin
                $display("takt %0d: d=%b prev=%b rise=%b fall=%b any=%b", k, d, prev, rise, fall, any);
                errors = errors + 1;
            end
            if (rise) n_rise = n_rise + 1;
            prev = d;
            @(negedge clk);
        end
        if (n_rise == 0) begin
            $display("brak zboczy w tescie"); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
