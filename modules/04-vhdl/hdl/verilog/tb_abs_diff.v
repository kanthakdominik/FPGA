// Testbench |a - b|: wszystkie pary liczb 4-bitowych bez znaku.
`default_nettype none
`timescale 1ns / 1ps

module tb_abs_diff;
    localparam integer W = 4;

    reg  [W-1:0] a, b;
    wire [W-1:0] y;
    wire         a_lt_b;

    abs_diff #(.W(W)) dut (.a(a), .b(b), .y(y), .a_lt_b(a_lt_b));

    integer errors = 0, i, j, e;

    initial begin
        for (i = 0; i < (1 << W); i = i + 1)
            for (j = 0; j < (1 << W); j = j + 1) begin
                a = i; b = j; #1;
                e = (i > j) ? i - j : j - i;
                if (y !== e || a_lt_b !== (i < j)) begin
                    $display("|%0d - %0d| = %0d", i, j, y); errors = errors + 1;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
