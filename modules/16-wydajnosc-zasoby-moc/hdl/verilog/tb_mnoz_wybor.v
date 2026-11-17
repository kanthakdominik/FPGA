// Testbench mnoz_wybor: obie wersje (dwie mnożarki / jedna współdzielona) na tych samych danych.
// Sprawdzane: wynik = sel ? a*b : c*d po jednym takcie, obie wersje identyczne.
`timescale 1ns / 1ps
`default_nettype none

module tb_mnoz_wybor;
    localparam W = 16;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg  [W-1:0] a = 0, b = 0, c = 0, d = 0;
    reg          sel = 1'b0;
    wire [2*W-1:0] y0, y1;
    mnoz_wybor #(.W(W), .WSPOLNY(0)) u0 (.clk(clk), .sel(sel), .a(a), .b(b), .c(c), .d(d), .y(y0));
    mnoz_wybor #(.W(W), .WSPOLNY(1)) u1 (.clk(clk), .sel(sel), .a(a), .b(b), .c(c), .d(d), .y(y1));

    reg [2*W-1:0] oczek;
    integer n = 0, errors = 0;
    always @(posedge clk) oczek <= sel ? a * b : c * d;

    always @(negedge clk) begin
        if (n > 0) begin
            if (y0 !== oczek || y1 !== oczek) begin
                $display("%0t: y0=%0d y1=%0d, oczekiwano %0d", $time, y0, y1, oczek);
                errors = errors + 1;
            end
        end
        n = n + 1;
        a = $random; b = $random; c = $random; d = $random;
        if ($random % 8 == 0) a = {W{1'b1}};
        if ($random % 8 == 0) d = {W{1'b1}};
        sel = $random;
    end

    initial begin
        wait (n == 1000);
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin
        #100000 $display("FAIL: przekroczony czas"); $finish;
    end
endmodule

`default_nettype wire
