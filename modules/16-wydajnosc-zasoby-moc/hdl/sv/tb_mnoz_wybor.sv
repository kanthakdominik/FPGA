// Testbench mnoz_wybor: obie wersje na tych samych danych; wynik = sel ? a*b : c*d po jednym takcie.
`timescale 1ns / 1ps

module tb_mnoz_wybor;
    localparam int W = 16;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic [W-1:0]   a = '0, b = '0, c = '0, d = '0;
    logic           sel = 1'b0;
    logic [2*W-1:0] y0, y1, oczek;
    mnoz_wybor #(.W(W), .WSPOLNY(1'b0)) u0 (.clk, .sel, .a, .b, .c, .d, .y(y0));
    mnoz_wybor #(.W(W), .WSPOLNY(1'b1)) u1 (.clk, .sel, .a, .b, .c, .d, .y(y1));

    int n = 0, errors = 0;
    always @(posedge clk) oczek <= sel ? (2*W)'(a) * (2*W)'(b) : (2*W)'(c) * (2*W)'(d);

    always @(negedge clk) begin
        if (n > 0 && (y0 !== oczek || y1 !== oczek)) begin
            $display("%0t: y0=%0d y1=%0d, oczekiwano %0d", $time, y0, y1, oczek);
            errors++;
        end
        n++;
        a = W'($urandom); b = W'($urandom); c = W'($urandom); d = W'($urandom);
        if ($urandom_range(7) == 0) a = '1;
        if ($urandom_range(7) == 0) d = '1;
        sel = 1'($urandom);
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
