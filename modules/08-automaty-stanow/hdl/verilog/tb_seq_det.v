// Testbench detektorów 1011 (Moore i Mealy): ustalony ciąg z nakładającymi się wzorcami, potem losowe bity.
// Model: rejestr ostatnich bitów. Moore: y = 1, gdy ostatnie 4 PRZYJĘTE bity to 1011 (takt później);
// Mealy: y = 1, gdy ostatnie 3 przyjęte bity to 101, a bieżący x = 1 (w tym samym takcie).
`default_nettype none
`timescale 1ns / 1ps

module tb_seq_det;
    reg  clk = 1'b0, rst = 1'b1, x = 1'b0;
    wire y_moore, y_mealy;

    always #5 clk = ~clk;

    seq_det_moore u_moore (.clk(clk), .rst(rst), .x(x), .y(y_moore));
    seq_det_mealy u_mealy (.clk(clk), .rst(rst), .x(x), .y(y_mealy));

    localparam [15:0] PAT = 16'b1011_0111_0110_0101;   // 1011 z nakładaniem: „1011011”, „…10111…”
    reg [3:0] hist = 4'b0000;                          // przyjęte bity, najnowszy w hist[0]
    integer errors = 0, n, hits_moore = 0, hits_mealy = 0, seed = 17;

    initial begin
        @(negedge clk);
        @(negedge clk) rst = 1'b0;
        for (n = 0; n < 2000; n = n + 1) begin
            if (y_moore !== (hist == 4'b1011)) begin
                $display("bit %0d: Moore y=%b, historia %b", n, y_moore, hist); errors = errors + 1;
            end
            if (y_moore) hits_moore = hits_moore + 1;
            x = (n < 16) ? PAT[15-n] : ($random(seed) & 1);
            #1;
            if (y_mealy !== (hist[2:0] == 3'b101 && x)) begin
                $display("bit %0d: Mealy y=%b, historia %b, x=%b", n, y_mealy, hist, x); errors = errors + 1;
            end
            if (y_mealy) hits_mealy = hits_mealy + 1;
            @(negedge clk);                            // zbocze przyjęło x
            hist = {hist[2:0], x};
        end

        // Moore zgłasza każde wykrycie takt później — liczby różnią się najwyżej o ostatnie wykrycie
        if (hits_mealy < 50 || hits_moore > hits_mealy || hits_mealy - hits_moore > 1) begin
            $display("wykrycia: Moore %0d, Mealy %0d", hits_moore, hits_mealy); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
