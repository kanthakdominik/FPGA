// Testbench cnt10: 200 taktów z losowym en, model w zmiennej; sprawdzane q i wrap w każdym takcie.
`default_nettype none
`timescale 1ns / 1ps

module tb_cnt10;
    reg        clk = 1'b0, rst = 1'b1, en = 1'b0;
    wire [3:0] q;
    wire       wrap;
    integer    m = 0, errors = 0, n_wrap = 0, n, seed = 13;

    always #5 clk = ~clk;

    cnt10 dut (.clk(clk), .rst(rst), .en(en), .q(q), .wrap(wrap));

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (n = 0; n < 200; n = n + 1) begin
            en = ($random(seed) & 3) != 0;
            #1;
            if (q !== m || wrap !== (en && m == 9)) begin
                $display("takt %0d: q=%0d wrap=%b, oczekiwano %0d", n, q, wrap, m);
                errors = errors + 1;
            end
            if (wrap) n_wrap = n_wrap + 1;
            if (en) m = (m == 9) ? 0 : m + 1;
            @(negedge clk);
        end
        if (n_wrap == 0) begin $display("pokrycie: brak wrap"); errors = errors + 1; end
        $display("przejsc 9 -> 0: %0d", n_wrap);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
