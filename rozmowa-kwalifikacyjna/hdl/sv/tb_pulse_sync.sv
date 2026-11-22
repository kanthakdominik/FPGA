// Testbench (SystemVerilog) zadania 7: dwa egzemplarze — z szybkiej domeny do wolnej (10 ns -> 27 ns, impulsy co 12 taktów A)
// i z wolnej do szybkiej (27 ns -> 10 ns, impulsy co 3 takty A). Liczba impulsów po stronie B musi się zgadzać,
// a każdy impuls B trwa dokładnie jeden takt.
`timescale 1ns / 1ps
`default_nettype none

module tb_pulse_sync;
    logic  clk_f = 1'b0;
    logic  clk_s = 1'b0;
    logic  rst = 1'b1;
    logic  p_fs = 1'b0;
    logic  p_sf = 1'b0;
    logic q_fs, q_sf;
    always #5    clk_f = ~clk_f;
    always #13.5 clk_s = ~clk_s;

    pulse_sync u_fs (.clk_a(clk_f), .rst_a(rst), .pulse_a(p_fs), .clk_b(clk_s), .rst_b(rst), .pulse_b(q_fs));
    pulse_sync u_sf (.clk_a(clk_s), .rst_a(rst), .pulse_a(p_sf), .clk_b(clk_f), .rst_b(rst), .pulse_b(q_sf));

    localparam int N = 60;
    int errors = 0, sent_fs = 0, sent_sf = 0, got_fs = 0, got_sf = 0, i, j;
    logic     q_fs_p = 1'b0;
    logic     q_sf_p = 1'b0;

    always @(posedge clk_s) begin
        if (q_fs) got_fs = got_fs + 1;
        if (q_fs && q_fs_p) begin $display("%0t: impuls szybka->wolna dluzszy niz takt", $time); errors = errors + 1; end
        q_fs_p = q_fs;
        if (p_sf) sent_sf = sent_sf + 1;
    end
    always @(posedge clk_f) begin
        if (q_sf) got_sf = got_sf + 1;
        if (q_sf && q_sf_p) begin $display("%0t: impuls wolna->szybka dluzszy niz takt", $time); errors = errors + 1; end
        q_sf_p = q_sf;
        if (p_fs) sent_fs = sent_fs + 1;
    end

    initial begin
        #100;
        @(negedge clk_s) rst = 1'b0;
        fork
            for (i = 0; i < N; i = i + 1) begin
                @(negedge clk_f) p_fs = 1'b1;
                @(negedge clk_f) p_fs = 1'b0;
                repeat (11) @(negedge clk_f);
            end
            for (j = 0; j < N; j = j + 1) begin
                @(negedge clk_s) p_sf = 1'b1;
                @(negedge clk_s) p_sf = 1'b0;
                repeat (2) @(negedge clk_s);
            end
        join
        #300;
        $display("szybka->wolna: wyslano %0d, odebrano %0d; wolna->szybka: wyslano %0d, odebrano %0d",
                 sent_fs, got_fs, sent_sf, got_sf);
        if (sent_fs != N || got_fs != N || sent_sf != N || got_sf != N) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #200000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
