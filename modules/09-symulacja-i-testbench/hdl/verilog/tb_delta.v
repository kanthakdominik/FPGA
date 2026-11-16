// Demonstracja szeregowania zdarzeń w symulatorze Verilog — testbench bez układu badanego.
// Sprawdza trzy zachowania wynikające ze standardu (IEEE 1364, regiony active i NBA):
//   1. zamiana dwóch rejestrów przypisaniami nieblokującymi działa (oba czytają wartości sprzed zbocza),
//   2. ta sama zamiana przypisaniami blokującymi w dwóch blokach daje wyścig: wynik zależy od kolejności
//      wykonania bloków, ale zawsze a == b (zamiana NIE następuje),
//   3. rejestr taktowany „kopią zegara” (assign clk_copy = clk) dostaje starą wartość rejestru z clk —
//      bo aktualizacje nieblokujące następują dopiero po wszystkich zdarzeniach aktywnych.
`default_nettype none
`timescale 1ns / 1ps

module tb_delta;
    reg clk = 1'b0;
    always #5 clk = ~clk;

    // 1. zamiana przypisaniami nieblokującymi
    reg [7:0] a_nb = 8'd1, b_nb = 8'd2;
    always @(posedge clk) a_nb <= b_nb;
    always @(posedge clk) b_nb <= a_nb;

    // 2. „zamiana” przypisaniami blokującymi — wyścig między blokami
    reg [7:0] a_b = 8'd1, b_b = 8'd2;
    always @(posedge clk) a_b = b_b;
    always @(posedge clk) b_b = a_b;

    // 3. zegar pochodny przez przypisanie ciągłe
    wire      clk_copy;
    reg [7:0] q = 8'd0, q2 = 8'd0;
    assign clk_copy = clk;
    always @(posedge clk)      q  <= q + 8'd1;
    always @(posedge clk_copy) q2 <= q;

    integer errors = 0, n;

    initial begin
        for (n = 1; n <= 6; n = n + 1) begin
            @(negedge clk);                    // po n-tym zboczu narastającym
            if (a_nb !== (n % 2 ? 8'd2 : 8'd1) || b_nb !== (n % 2 ? 8'd1 : 8'd2)) begin
                $display("zbocze %0d: zamiana <= nie zadzialala: a=%0d b=%0d", n, a_nb, b_nb); errors = errors + 1;
            end
            if (a_b !== b_b) begin
                $display("zbocze %0d: przypisania blokujace: a=%0d b=%0d (oczekiwano rownych)", n, a_b, b_b); errors = errors + 1;
            end
            if (q !== n || q2 !== n - 1) begin
                $display("zbocze %0d: q=%0d q2=%0d (q2 powinno byc o 1 mniejsze)", n, q, q2); errors = errors + 1;
            end
        end
        $display("blokujace po wyscigu: a=b=%0d (wartosc zalezy od kolejnosci blokow w symulatorze)", a_b);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
