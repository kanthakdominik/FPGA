// Testbench adder_tree: wersja kombinacyjna i potokowa (N = 8), N = 16 z W = 4 oraz N = 2.
// Wynik porównany z sumą sprzed LATENCY taktów; co 50 taktów same maksima (sprawdzenie szerokości).
`timescale 1ns / 1ps

module tb_adder_tree;
    logic             clk = 1'b0;
    logic [7:0][7:0]  x8  = '0;                // N = 8,  W = 8
    logic [15:0][3:0] x16 = '0;                // N = 16, W = 4
    logic [1:0][7:0]  x2  = '0;                // N = 2,  W = 8
    logic [10:0]      s8c, s8p;
    logic [7:0]       s16;
    logic [8:0]       s2;

    always #5 clk = ~clk;

    adder_tree #(.N(8),  .W(8), .PIPELINED(1'b0)) u_8c  (.clk, .x(x8),  .sum(s8c));
    adder_tree #(.N(8),  .W(8), .PIPELINED(1'b1)) u_8p  (.clk, .x(x8),  .sum(s8p));
    adder_tree #(.N(16), .W(4), .PIPELINED(1'b1)) u_16p (.clk, .x(x16), .sum(s16));
    adder_tree #(.N(2),  .W(8), .PIPELINED(1'b1)) u_2p  (.clk, .x(x2),  .sum(s2));

    int h8 [300], h16 [300], h2 [300];
    int errors = 0;

    initial begin
        for (int c = 0; c < 300; c++) begin
            @(negedge clk);
            // wyjścia potokowe: suma wejść sprzed log2(N) taktów
            if (c >= 3 && int'(s8p) != h8[c-3])  begin $display("c=%0d: N=8 potok %0d != %0d", c, s8p, h8[c-3]);  errors++; end
            if (c >= 4 && int'(s16) != h16[c-4]) begin $display("c=%0d: N=16 %0d != %0d", c, s16, h16[c-4]);      errors++; end
            if (c >= 1 && int'(s2)  != h2[c-1])  begin $display("c=%0d: N=2 %0d != %0d", c, s2, h2[c-1]);          errors++; end
            if (c % 50 == 7) begin
                x8 = '1; x16 = '1; x2 = '1;
            end else begin
                x8  = {$urandom, $urandom};
                x16 = {$urandom, $urandom};
                x2  = 16'($urandom);
            end
            h8[c]  = 0; for (int i = 0; i < 8;  i++) h8[c]  += int'(x8[i]);
            h16[c] = 0; for (int i = 0; i < 16; i++) h16[c] += int'(x16[i]);
            h2[c]  = 0; for (int i = 0; i < 2;  i++) h2[c]  += int'(x2[i]);
            #1;
            if (int'(s8c) != h8[c]) begin $display("c=%0d: N=8 komb. %0d != %0d", c, s8c, h8[c]); errors++; end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
