// Testbench gray_cdc i synchronizacji wielobitowej. Część 1: układ gray_cdc (100 MHz -> 36,6 MHz) — kolejne
// odczyty w domenie docelowej różnią się o 0…4 (licznik źródłowy rośnie najwyżej o 1 na takt).
// Część 2: przyczyna — ten sam licznik 4-bitowy wysłany do synchronizatorów z rozrzutem opóźnień bitów
// (0…2,1 ns, jak na różnych ścieżkach w układzie): w kodzie binarnym pojawiają się skoki, których licznik
// nigdy nie wykonał, w kodzie Graya — nigdy.
`default_nettype none
`timescale 1ns / 1ps

module tb_gray_cdc;
    localparam W = 4;
    reg  clk_f = 1'b0, clk_s = 1'b0, rst = 1'b1, inc = 1'b0;
    always #5     clk_f = ~clk_f;
    always #13.65 clk_s = ~clk_s;

    wire [W-1:0] src_count, dst_count;
    gray_cdc #(.W(W)) dut (.clk_src(clk_f), .rst_src(rst), .inc(inc), .src_count(src_count),
                           .clk_dst(clk_s), .dst_count(dst_count));

    integer errors = 0, n_prob = 0, zle_bin = 0, zle_gray = 0, seed = 11, i;
    reg [W-1:0] dst_prev = 4'd0, roz;
    always @(negedge clk_f) inc <= $random(seed) & 1;

    always @(negedge clk_s) if (!rst) begin
        n_prob = n_prob + 1;
        roz = dst_count - dst_prev;
        if (roz > 4) begin $display("%0t: skok %0d -> %0d", $time, dst_prev, dst_count); errors = errors + 1; end
        dst_prev = dst_count;
    end

    // ---- część 2: rozrzut opóźnień bitów przed synchronizatorem ----
    reg  [W-1:0] bin_r = 4'd0, gray_r = 4'd0, bin_prev = 4'd0, gray_prev = 4'd0, b_now, g_now;
    wire [W-1:0] bin_sk, gray_sk, bin_s, gray_s;
    wire [W-1:0] bin_n = bin_r + 4'd1;
    always @(posedge clk_f) if (!rst) begin
        bin_r  <= bin_n;
        gray_r <= bin_n ^ (bin_n >> 1);
    end
    assign bin_sk[0] = bin_r[0];
    assign #0.7 bin_sk[1] = bin_r[1];
    assign #1.4 bin_sk[2] = bin_r[2];
    assign #2.1 bin_sk[3] = bin_r[3];
    assign gray_sk[0] = gray_r[0];
    assign #0.7 gray_sk[1] = gray_r[1];
    assign #1.4 gray_sk[2] = gray_r[2];
    assign #2.1 gray_sk[3] = gray_r[3];
    sync_bit #(.W(W)) u_bin  (.clk(clk_s), .d(bin_sk),  .q(bin_s));
    sync_bit #(.W(W)) u_gray (.clk(clk_s), .d(gray_sk), .q(gray_s));

    always @(posedge clk_s) if (!rst) begin
        #0.1;
        g_now[W-1] = gray_s[W-1];
        for (i = W - 2; i >= 0; i = i - 1) g_now[i] = g_now[i+1] ^ gray_s[i];
        b_now = bin_s;
        roz = b_now - bin_prev;
        if (roz > 4) zle_bin = zle_bin + 1;
        roz = g_now - gray_prev;
        if (roz > 4) zle_gray = zle_gray + 1;
        bin_prev  = b_now;
        gray_prev = g_now;
    end

    initial begin
        #100 rst = 1'b0;
        #60000;
        $display("gray_cdc: %0d probek; rozrzut bitow: wartosci bledne binarnie %0d, w kodzie Graya %0d",
                 n_prob, zle_bin, zle_gray);
        if (zle_gray != 0) errors = errors + 1;
        if (zle_bin == 0) begin $display("oczekiwano blednych wartosci w kodzie binarnym"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
