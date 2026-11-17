// Testbench gray_cdc i synchronizacji wielobitowej. Część 1: układ gray_cdc (100 MHz -> 36,6 MHz) — kolejne
// odczyty w domenie docelowej różnią się o 0…4 (licznik źródłowy rośnie najwyżej o 1 na takt). Część 2: przyczyna — ten sam licznik 4-bitowy wysłany do synchronizatorów z rozrzutem
// opóźnień bitów (0…2,1 ns, jak na różnych ścieżkach w układzie): w kodzie binarnym pojawiają się
// wartości, których licznik nigdy nie miał, w kodzie Graya — nigdy.
`timescale 1ns / 1ps

module tb_gray_cdc;
    localparam int W = 4;
    logic clk_f = 1'b0, clk_s = 1'b0, rst = 1'b1, inc = 1'b0;
    always #5     clk_f = ~clk_f;
    always #13.65 clk_s = ~clk_s;

    logic [W-1:0] src_count, dst_count;
    gray_cdc #(.W(W)) dut (.clk_src(clk_f), .rst_src(rst), .inc(inc), .src_count(src_count),
                           .clk_dst(clk_s), .dst_count(dst_count));

    always @(negedge clk_f) inc <= ($urandom_range(1) == 0);

    // kolejne odczyty w domenie docelowej: licznik rośnie o 0…4 (w okresie clk_s mieszczą się do 3 zmian
    // źródła plus jedna z niepewności synchronizacji) — wartość „przypadkowa” dałaby dowolny skok
    int errors = 0, n_prob = 0;
    logic [W-1:0] dst_prev = '0;
    always @(negedge clk_s) if (!rst) begin
        n_prob++;
        if (W'(dst_count - dst_prev) > 4) begin
            $display("%0t: skok %0d -> %0d", $time, dst_prev, dst_count); errors++;
        end
        dst_prev = dst_count;
    end

    // ---- część 2: rozrzut opóźnień bitów przed synchronizatorem ----
    logic [W-1:0] bin_r = '0, gray_r = '0, bin_sk, gray_sk, bin_s, gray_s;
    always @(posedge clk_f) if (!rst) begin
        bin_r  <= bin_r + 1'b1;
        gray_r <= (bin_r + 1'b1) ^ ((bin_r + 1'b1) >> 1);
    end
    for (genvar i = 0; i < W; i++) begin : g_skew
        assign #(i * 0.7) bin_sk[i]  = bin_r[i];
        assign #(i * 0.7) gray_sk[i] = gray_r[i];
    end
    sync_bit #(.W(W)) u_bin  (.clk(clk_s), .d(bin_sk),  .q(bin_s));
    sync_bit #(.W(W)) u_gray (.clk(clk_s), .d(gray_sk), .q(gray_s));

    function automatic logic [W-1:0] g2b(logic [W-1:0] g);
        logic [W-1:0] b;
        b[W-1] = g[W-1];
        for (int i = W - 2; i >= 0; i--) b[i] = b[i+1] ^ g[i];
        return b;
    endfunction
    int zle_bin = 0, zle_gray = 0;
    logic [W-1:0] bin_prev = '0, gray_prev = '0;
    always @(posedge clk_s) if (!rst) begin
        #0.1;
        // wartość odczytana musi być równa poprzedniej albo kolejnym (licznik +1 co takt clk_f,
        // w okresie clk_s mieści się do 3 zmian)
        if (W'(bin_s - bin_prev) > 4) zle_bin++;
        if (W'(g2b(gray_s) - g2b(gray_prev)) > 4) zle_gray++;
        bin_prev  = bin_s;
        gray_prev = gray_s;
    end

    initial begin
        #100 rst = 1'b0;
        #60000;
        $display("gray_cdc: %0d probek; rozrzut bitow: wartosci bledne binarnie %0d, w kodzie Graya %0d",
                 n_prob, zle_bin, zle_gray);
        if (zle_gray != 0) errors++;
        if (zle_bin == 0) begin $display("oczekiwano blednych wartosci w kodzie binarnym"); errors++; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
