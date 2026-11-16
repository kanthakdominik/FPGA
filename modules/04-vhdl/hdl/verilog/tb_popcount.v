// Testbench liczenia jedynek: wszystkie 256 wartości, model liczy bity dzieleniem przez 2.
`default_nettype none
`timescale 1ns / 1ps

module tb_popcount;
    localparam integer W = 8;

    reg  [W-1:0] d;
    wire [3:0]   count;

    popcount #(.W(W)) dut (.d(d), .count(count));

    integer errors = 0, i, v, n;

    initial begin
        for (i = 0; i < (1 << W); i = i + 1) begin
            d = i; #1;
            v = i; n = 0;
            while (v > 0) begin
                n = n + v % 2; v = v / 2;
            end
            if (count !== n) begin
                $display("popcount(%0d) = %0d", i, count); errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
