// Testbench adder_tree: wersja kombinacyjna i potokowa (N = 8), N = 16 z W = 4 oraz N = 2.
// Wynik porównany z sumą sprzed LATENCY taktów; co 50 taktów same maksima (sprawdzenie szerokości).
`default_nettype none
`timescale 1ns / 1ps

module tb_adder_tree;
    reg          clk = 1'b0;
    reg  [63:0]  x8  = 64'd0;                  // N = 8,  W = 8
    reg  [63:0]  x16 = 64'd0;                  // N = 16, W = 4
    reg  [15:0]  x2  = 16'd0;                  // N = 2,  W = 8
    wire [10:0]  s8c, s8p;
    wire [7:0]   s16;
    wire [8:0]   s2;

    always #5 clk = ~clk;

    adder_tree #(.N(8),  .W(8), .PIPELINED(0)) u_8c  (.clk(clk), .x(x8),  .sum(s8c));
    adder_tree #(.N(8),  .W(8), .PIPELINED(1)) u_8p  (.clk(clk), .x(x8),  .sum(s8p));
    adder_tree #(.N(16), .W(4), .PIPELINED(1)) u_16p (.clk(clk), .x(x16), .sum(s16));
    adder_tree #(.N(2),  .W(8), .PIPELINED(1)) u_2p  (.clk(clk), .x(x2),  .sum(s2));

    integer h8 [0:511], h16 [0:511], h2 [0:511];
    integer errors = 0, c, i, seed = 13;

    initial begin
        for (c = 0; c < 300; c = c + 1) begin
            @(negedge clk);
            // wyjścia potokowe: suma wejść sprzed log2(N) taktów
            if (c >= 3 && s8p !== h8[c-3])  begin $display("c=%0d: N=8 potok %0d != %0d", c, s8p, h8[c-3]);  errors = errors + 1; end
            if (c >= 4 && s16 !== h16[c-4]) begin $display("c=%0d: N=16 %0d != %0d", c, s16, h16[c-4]);      errors = errors + 1; end
            if (c >= 1 && s2  !== h2[c-1])  begin $display("c=%0d: N=2 %0d != %0d", c, s2, h2[c-1]);          errors = errors + 1; end
            if (c % 50 == 7) begin
                x8 = {64{1'b1}}; x16 = {64{1'b1}}; x2 = {16{1'b1}};
            end else begin
                x8  = {$random(seed), $random(seed)};
                x16 = {$random(seed), $random(seed)};
                x2  = $random(seed);
            end
            h8[c] = 0; h16[c] = 0; h2[c] = 0;
            for (i = 0; i < 8;  i = i + 1) h8[c]  = h8[c]  + x8[i*8 +: 8];
            for (i = 0; i < 16; i = i + 1) h16[c] = h16[c] + x16[i*4 +: 4];
            for (i = 0; i < 2;  i = i + 1) h2[c]  = h2[c]  + x2[i*8 +: 8];
            #1;
            if (s8c !== h8[c]) begin $display("c=%0d: N=8 komb. %0d != %0d", c, s8c, h8[c]); errors = errors + 1; end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
