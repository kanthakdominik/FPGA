// Testbench ram_sdp: (1) jeden zegar — zapis i odczyt w tym samym takcie, także pod ten sam adres
// (oczekiwana stara zawartość); (2) dwa zegary 100 MHz / 37 MHz — blok danych zapisany w jednej domenie,
// po sygnale gotowości (przekazanym przez synchronizator w testbenchu) odczytany w drugiej.
`timescale 1ns / 1ps
`default_nettype none

module tb_ram_sdp;
    localparam W = 16, AW = 6;
    reg clk = 1'b0, clk_r2 = 1'b0;
    always #5 clk = ~clk;
    initial begin #2.1 forever #13.5 clk_r2 = ~clk_r2; end

    // (1) jeden zegar
    reg           we = 1'b0, re = 1'b0;
    reg  [AW-1:0] aw = 0, ar = 0;
    reg  [W-1:0]  din = 0;
    wire [W-1:0]  dout;
    ram_sdp #(.W(W), .AW(AW)) u1 (.clk_w(clk), .we(we), .addr_w(aw), .din(din),
                                  .clk_r(clk), .re(re), .addr_r(ar), .dout(dout));
    // (2) dwa zegary
    reg           we2 = 1'b0, re2 = 1'b0;
    reg  [AW-1:0] aw2 = 0, ar2 = 0;
    reg  [W-1:0]  din2 = 0;
    wire [W-1:0]  dout2;
    ram_sdp #(.W(W), .AW(AW)) u2 (.clk_w(clk), .we(we2), .addr_w(aw2), .din(din2),
                                  .clk_r(clk_r2), .re(re2), .addr_r(ar2), .dout(dout2));

    reg [W-1:0] model [0:(1<<AW)-1];
    reg [W-1:0] oczek;
    integer i, n, errors = 0, rdw = 0;

    initial begin
        for (i = 0; i < (1 << AW); i = i + 1) begin
            @(negedge clk) we = 1'b1; aw = i; din = $random; model[i] = din;
        end
        for (n = 0; n < 1000; n = n + 1) begin
            @(negedge clk);
            we = $random; re = 1'b1; aw = $random; ar = (n % 4 == 0) ? aw : $random; din = $random;
            oczek = model[ar];                          // stara zawartość także przy ar == aw
            if (we && ar == aw) rdw = rdw + 1;
            if (we) model[aw] = din;
            @(posedge clk); #1;
            if (dout !== oczek) begin
                $display("%0t: jeden zegar: adres %0d: %h, oczekiwano %h", $time, ar, dout, oczek);
                errors = errors + 1;
            end
        end
        we = 1'b0;
        // (2) blok 64 słów zapisany zegarem 100 MHz, odczytany zegarem 37 MHz
        for (i = 0; i < (1 << AW); i = i + 1) begin
            @(negedge clk) we2 = 1'b1; aw2 = i; din2 = 16'hA000 + i * 3;
        end
        @(negedge clk) we2 = 1'b0;
        repeat (3) @(posedge clk_r2);                   // gotowość przez dwa przerzutniki domeny odczytu
        for (i = 0; i < (1 << AW); i = i + 1) begin
            @(negedge clk_r2) re2 = 1'b1; ar2 = i;
            @(posedge clk_r2); #1;
            if (dout2 !== 16'hA000 + i * 3) begin
                $display("dwa zegary: adres %0d: %h", i, dout2);
                errors = errors + 1;
            end
        end
        $display("odczytow pod adres zapisywany w tym samym takcie: %0d", rdw);
        if (errors == 0 && rdw > 50) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
