// Testbench max_n: łańcuch i drzewo na tych samych danych; wynik = maksimum z 16 wejść po 2 taktach.
`timescale 1ns / 1ps

module tb_max_n;
    localparam int W = 8;
    logic clk = 1'b0;
    always #5 clk = ~clk;

    logic [16*W-1:0] x = '0;
    logic [W-1:0]    y_l, y_d, o1, o2;
    max_n #(.W(W), .DRZEWO(1'b0)) u_l (.clk, .x, .y(y_l));
    max_n #(.W(W), .DRZEWO(1'b1)) u_d (.clk, .x, .y(y_d));

    int n = 0, errors = 0;
    always @(posedge clk) begin
        logic [W-1:0] m;
        m = '0;
        for (int i = 0; i < 16; i++) if (x[i*W +: W] > m) m = x[i*W +: W];
        o1 <= m;
        o2 <= o1;
    end

    always @(negedge clk) begin
        if (n > 2 && (y_l !== o2 || y_d !== o2)) begin
            $display("%0t: lancuch %0d, drzewo %0d, oczekiwano %0d", $time, y_l, y_d, o2);
            errors++;
        end
        n++;
        for (int i = 0; i < 16; i++) x[i*W +: W] = (n % 5 == 0) ? 8'd7 : W'($urandom);
        if (n % 7 == 0)  x[0 +: W]    = '1;
        if (n % 11 == 0) x[15*W +: W] = '1;
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
