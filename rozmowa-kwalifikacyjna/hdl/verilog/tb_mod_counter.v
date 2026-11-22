// Testbench zadania 2: dwa liczniki (N = 10 i N = 6) z losowym zezwoleniem; w każdym takcie porównanie q i carry
// z modelem, na końcu liczba przeniesień = liczba taktów z zezwoleniem / N.
`timescale 1ns / 1ps
`default_nettype none

module tb_mod_counter;
    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg        en = 1'b0;
    wire [3:0] q10;
    wire [2:0] q6;
    wire       c10, c6;
    always #5 clk = ~clk;

    mod_counter #(.N(10)) dut10 (.clk(clk), .rst(rst), .en(en), .q(q10), .carry(c10));
    mod_counter #(.N(6))  dut6  (.clk(clk), .rst(rst), .en(en), .q(q6), .carry(c6));

    integer errors = 0, m10 = 0, m6 = 0, n_en = 0, n_c10 = 0, n_c6 = 0, i, seed = 3;

    always @(posedge clk)
        if (!rst) begin
            if (q10 != m10 || q6 != m6 || c10 !== (en && m10 == 9) || c6 !== (en && m6 == 5)) begin
                $display("%0t: q10=%0d (model %0d) c10=%b, q6=%0d (model %0d) c6=%b", $time, q10, m10, c10, q6, m6, c6);
                errors = errors + 1;
            end
            if (c10) n_c10 = n_c10 + 1;
            if (c6)  n_c6 = n_c6 + 1;
            if (en) begin
                n_en = n_en + 1;
                m10 = (m10 + 1) % 10;
                m6  = (m6 + 1) % 6;
            end
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 600; i = i + 1) begin
            @(negedge clk);
            en = ($unsigned($random(seed)) % 4 != 0);
        end
        @(negedge clk) en = 1'b0;
        @(negedge clk);
        $display("taktow z en %0d, przeniesien N=10: %0d, N=6: %0d", n_en, n_c10, n_c6);
        if (n_c10 != n_en / 10 || n_c6 != n_en / 6) begin $display("zla liczba przeniesien"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #100000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
