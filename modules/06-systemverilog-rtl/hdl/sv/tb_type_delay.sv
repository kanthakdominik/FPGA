// Testbench linii opóźniającej parametryzowanej typem: struktura rgb_t (DEPTH = 2) i wektor 8-bitowy (DEPTH = 1).
`timescale 1ns / 1ps

module tb_type_delay;
    import img_pkg::*;

    logic       clk = 1'b0;
    rgb_t       d_rgb = '0, q_rgb;
    logic [7:0] d_8 = '0, q_8;
    rgb_t       hist [$];

    always #5 clk = ~clk;

    type_delay #(.T(rgb_t), .DEPTH(2)) u_rgb (.clk, .d(d_rgb), .q(q_rgb));
    type_delay #(.DEPTH(1))            u_8   (.clk, .d(d_8),   .q(q_8));

    int errors = 0;

    initial begin
        logic [23:0] lfsr = 24'hABCDEF;
        logic [7:0]  prev8 = '0;
        for (int k = 0; k < 50; k++) begin
            @(negedge clk);
            if (k >= 2 && q_rgb != hist[k-2]) begin
                $display("takt %0d: rgb q=%h oczekiwano %h", k, q_rgb, hist[k-2]); errors++;
            end
            if (k >= 1 && q_8 != prev8) begin
                $display("takt %0d: 8 bit q=%h oczekiwano %h", k, q_8, prev8); errors++;
            end
            lfsr  = lfsr[0] ? ((lfsr >> 1) ^ 24'hE10000) : (lfsr >> 1);
            d_rgb = rgb_t'(lfsr);                        // rzutowanie wektora na strukturę
            hist.push_back(d_rgb);
            prev8 = d_8;
            d_8   = lfsr[7:0] ^ lfsr[15:8];
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
