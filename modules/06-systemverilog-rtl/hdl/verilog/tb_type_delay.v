// Testbench linii opóźniającej: piksel 24-bitowy (DEPTH = 2) i wektor 8-bitowy (DEPTH = 1).
`default_nettype none
`timescale 1ns / 1ps

module tb_type_delay;
    reg         clk = 1'b0;
    reg  [23:0] d_rgb = 0;
    wire [23:0] q_rgb;
    reg  [7:0]  d_8 = 0, prev8 = 0;
    wire [7:0]  q_8;
    reg  [23:0] hist [0:49];
    reg  [23:0] lfsr = 24'hABCDEF;

    always #5 clk = ~clk;

    type_delay #(.W(24), .DEPTH(2)) u_rgb (.clk(clk), .d(d_rgb), .q(q_rgb));
    type_delay #(.W(8),  .DEPTH(1)) u_8   (.clk(clk), .d(d_8),   .q(q_8));

    integer errors = 0, k;

    initial begin
        for (k = 0; k < 50; k = k + 1) begin
            @(negedge clk);
            if (k >= 2 && q_rgb !== hist[k-2]) begin
                $display("takt %0d: rgb q=%h oczekiwano %h", k, q_rgb, hist[k-2]); errors = errors + 1;
            end
            if (k >= 1 && q_8 !== prev8) begin
                $display("takt %0d: 8 bit q=%h oczekiwano %h", k, q_8, prev8); errors = errors + 1;
            end
            lfsr    = lfsr[0] ? ((lfsr >> 1) ^ 24'hE10000) : (lfsr >> 1);
            d_rgb   = lfsr;
            hist[k] = lfsr;
            prev8   = lfsr[7:0] ^ lfsr[15:8];        // wartość podana teraz pojawi się po 1 takcie
            d_8     = prev8;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
