// Testbench max_n: łańcuch i drzewo na tych samych danych. Sprawdzane: wynik = maksimum z 16 wejść
// po 2 taktach, obie wersje identyczne (także przy równych wartościach i maksimum na krańcach).
`timescale 1ns / 1ps
`default_nettype none

module tb_max_n;
    localparam W = 8;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg  [16*W-1:0] x = 0;
    wire [W-1:0]    y_l, y_d;
    max_n #(.W(W), .DRZEWO(0)) u_l (.clk(clk), .x(x), .y(y_l));
    max_n #(.W(W), .DRZEWO(1)) u_d (.clk(clk), .x(x), .y(y_d));

    reg [W-1:0] m, o1, o2;
    integer n = 0, errors = 0, i;
    always @(posedge clk) begin
        m = {W{1'b0}};
        for (i = 0; i < 16; i = i + 1) if (x[i*W +: W] > m) m = x[i*W +: W];
        o1 <= m;
        o2 <= o1;
    end

    always @(negedge clk) begin
        if (n > 2 && (y_l !== o2 || y_d !== o2)) begin
            $display("%0t: lancuch %0d, drzewo %0d, oczekiwano %0d", $time, y_l, y_d, o2);
            errors = errors + 1;
        end
        n = n + 1;
        for (i = 0; i < 16; i = i + 1) x[i*W +: W] = (n % 5 == 0) ? 8'd7 : $random;
        if (n % 7 == 0) x[0 +: W] = {W{1'b1}};
        if (n % 11 == 0) x[15*W +: W] = {W{1'b1}};
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
