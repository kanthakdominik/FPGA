// Testbench (SystemVerilog) zadania 3: zegar 100 MHz (okres 10 ns). Mierzone czasy zboczy clk_out: okres musi wynosić 30 ns,
// stan wysoki 15 ns (wypełnienie 50 %) w każdym z 20 okresów.
`timescale 1ns / 1ps
`default_nettype none

module tb_clk_div3;
    logic  clk = 1'b0;
    logic  rst = 1'b1;
    logic clk_out;
    always #5 clk = ~clk;

    clk_div3 dut (.clk(clk), .rst(rst), .clk_out(clk_out));

    int errors = 0, n = 0;
    time    t_rise = 0, t_fall = 0, t_prev = 0;

    always @(posedge clk_out) begin
        t_prev = t_rise;
        t_rise = $time;
        if (n > 0 && t_rise - t_prev != 30) begin
            $display("%0t: okres %0d ns, oczekiwano 30", $time, t_rise - t_prev); errors = errors + 1;
        end
    end
    always @(negedge clk_out) begin
        t_fall = $time;
        n = n + 1;
        if (t_fall - t_rise != 15) begin
            $display("%0t: stan wysoki %0d ns, oczekiwano 15", $time, t_fall - t_rise); errors = errors + 1;
        end
    end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        wait (n == 20);
        $display("okresow %0d, ostatni: okres %0d ns, stan wysoki %0d ns", n, t_rise - t_prev, t_fall - t_rise);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #100000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
