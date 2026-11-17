// Testbench cnt10: 200 taktów z losowym en, model w zmiennej; sprawdzane q i wrap w każdym takcie.
`timescale 1ns / 1ps

module tb_cnt10;
    logic       clk = 1'b0, rst = 1'b1, en = 1'b0;
    logic [3:0] q;
    logic       wrap;
    int         m = 0, errors = 0, n_wrap = 0;

    always #5 clk = ~clk;

    cnt10 dut (.*);

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (int n = 0; n < 200; n++) begin
            en = 1'($urandom_range(3) != 0);
            #1;
            if (q !== 4'(m) || wrap !== (en && m == 9)) begin
                $display("takt %0d: q=%0d wrap=%b, oczekiwano %0d %b", n, q, wrap, m, en && m == 9);
                errors++;
            end
            if (wrap) n_wrap++;
            if (en) m = (m == 9) ? 0 : m + 1;
            @(negedge clk);
        end
        if (n_wrap == 0) begin $display("pokrycie: brak wrap"); errors++; end
        $display("przejsc 9 -> 0: %0d", n_wrap);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
