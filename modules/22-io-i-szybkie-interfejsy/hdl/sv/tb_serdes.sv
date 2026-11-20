// Testbench (SystemVerilog) 22.03: ser_tx (8:1) -> kanał z opóźnieniem 0–7 bitów -> deser_rx -> wyrownaj -> prbs7_spr.
// Dla każdego opóźnienia: trening słowem 0x6B, automat wyrównania przesuwa granicę słowa (bitslip) aż do
// 8 zgodnych słów z rzędu; potem nadajnik przechodzi na dane PRBS7 (8 bitów na słowo), a kontroler
// sprawdza 300 słów. Wynik: liczba poślizgów potrzebna dla każdego opóźnienia i 0 błędów danych.
`timescale 1ns / 1ps
`default_nettype none

module tb_serdes;
    logic clk = 1'b0;
    always #1 clk = ~clk;                         // zegar bitowy
    logic rst = 1'b1, rst_spr = 1'b1, trening = 1'b1;
    int errors = 0;

    logic [7:0] dane_prbs, slowo_rx;
    logic       pobierz, q, wazne, bitslip, wyrownane;
    logic [7:0] poslizgi;
    logic [15:0] bledy;
    logic       synch;
    logic  [15:0] linia = 16'd0;
    int    opozn = 0;

    prbs7 #(.N(8)) u_gen (.clk(clk), .rst(rst), .en(pobierz), .q(dane_prbs));
    ser_tx #(.N(8)) u_ser (.clk(clk), .rst(rst), .slowo(trening ? 8'h6B : dane_prbs), .pobierz(pobierz), .q(q));
    always @(posedge clk) linia <= {linia[14:0], q};
    logic wej;
    assign wej = (opozn == 0) ? q : linia[opozn - 1];
    deser_rx #(.N(8)) u_des (.clk(clk), .rst(rst), .d(wej), .bitslip(bitslip), .slowo(slowo_rx), .wazne(wazne));
    wyrownaj #(.N(8), .WZOR(8'h6B), .ILE(8)) u_wyr (.clk(clk), .rst(rst), .slowo(slowo_rx), .wazne(wazne),
        .bitslip(bitslip), .wyrownane(wyrownane), .poslizgi(poslizgi));
    prbs7_spr #(.N(8)) u_spr (.clk(clk), .rst(rst_spr), .en(wazne), .d(slowo_rx), .bledy(bledy), .synch(synch));

    int n, d;
    initial begin
        for (d = 0; d < 8; d = d + 1) begin
            opozn   = d;
            rst     = 1'b1;
            rst_spr = 1'b1;
            trening = 1'b1;
            repeat (20) @(negedge clk);
            rst = 1'b0;
            n = 0;
            while (!wyrownane && n < 2000) begin @(negedge clk); n = n + 1; end
            trening = 1'b0;
            repeat (8 * 6) @(negedge clk);           // słowa treningowe w drodze
            rst_spr = 1'b0;
            repeat (8 * 300) @(negedge clk);
            $display("opoznienie %0d bit: wyrownanie po %0d poslizgach, %0d bitow; bledy danych %0d", d, poslizgi, n,
                     bledy);
            if (!wyrownane || bledy != 0 || !synch) errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
