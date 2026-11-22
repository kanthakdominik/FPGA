// Testbench (SystemVerilog) 29.04: licznik_tmr z głosowaniem i resynchronizacją (SPRZEZENIE = 1) i bez (0), te same
// wstrzyknięcia błędów: pojedyncze w różnych kopiach i dwa w tym samym bicie dwóch kopii (odstęp 64 takty —
// ten sam stan bitu 5). Wzorzec: zwykły licznik. Wersja z resynchronizacją nie może się pomylić ani razu.
`timescale 1ns / 1ps
`default_nettype none

module tb_tmr;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [2:0]  wstrzyk = 3'd0;
    logic  [3:0]  bit_ = 4'd0;
    logic [15:0] q1, q0;
    logic        n1, n0;
    licznik_tmr #(.W(16), .SPRZEZENIE(1)) u1 (.clk(clk), .rst(rst), .en(1'b1), .wstrzyk(wstrzyk), .wstrzyk_bit(bit_), .q(q1), .niezgodny(n1));
    licznik_tmr #(.W(16), .SPRZEZENIE(0)) u0 (.clk(clk), .rst(rst), .en(1'b1), .wstrzyk(wstrzyk), .wstrzyk_bit(bit_), .q(q0), .niezgodny(n0));

    logic  [15:0] wzor = 16'd0;
    int t = 0;
    int zle1 = 0;
    int zle0 = 0;
    int niez1 = 0;
    int niez0 = 0;
    int pierwszy0 = -1;
    always @(posedge clk) if (!rst) begin
        if (q1 !== wzor) zle1 = zle1 + 1;
        if (q0 !== wzor) begin zle0 = zle0 + 1; if (pierwszy0 < 0) pierwszy0 = t; end
        if (n1) niez1 = niez1 + 1;
        if (n0) niez0 = niez0 + 1;
        wzor <= wzor + 16'd1;
        t = t + 1;
    end

    task wstrzyknij(input [2:0] k, input [3:0] b);
        begin
            @(negedge clk) begin wstrzyk = k; bit_ = b; end
            @(negedge clk) wstrzyk = 3'd0;
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        repeat (100) @(negedge clk);
        wstrzyknij(3'b001, 4'd3);                 // kopia 0, bit 3
        repeat (50) @(negedge clk);
        wstrzyknij(3'b100, 4'd12);                // kopia 2, bit 12
        repeat (50) @(negedge clk);
        wstrzyknij(3'b001, 4'd5);                 // kopia 0, bit 5 …
        repeat (63) @(negedge clk);
        wstrzyknij(3'b010, 4'd5);                 // … i 64 takty później kopia 1, bit 5
        repeat (300) @(negedge clk);
        $display("TMR z resynchronizacja: blednych wynikow %0d, taktow z niezgodnoscia kopii %0d (4 wstrzykniecia)", zle1, niez1);
        $display("TMR bez resynchronizacji: blednych wynikow %0d (od taktu %0d), taktow z niezgodnoscia %0d", zle0, pierwszy0, niez0);
        if (zle1 != 0 || niez1 != 4) errors = errors + 1;
        if (zle0 == 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
