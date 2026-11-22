// Testbench zadania 1: losowe d (zmiana na zboczu opadającym), w każdym takcie porównanie rise i fall z modelem
// (poprzednia próbka d), zliczenie zboczy obu rodzajów.
`timescale 1ns / 1ps
`default_nettype none

module tb_edge_detect;
    reg  clk = 1'b0;
    reg  rst = 1'b1;
    reg  d = 1'b0;
    wire rise, fall;
    always #5 clk = ~clk;

    edge_detect dut (.clk(clk), .rst(rst), .d(d), .rise(rise), .fall(fall));

    integer errors = 0, n_rise = 0, n_fall = 0, i, seed = 11;
    reg     prev = 1'b0;

    always @(posedge clk)
        if (!rst) begin
            if (rise !== (d & ~prev) || fall !== (~d & prev)) begin
                $display("%0t: d=%b poprzednie=%b rise=%b fall=%b", $time, d, prev, rise, fall);
                errors = errors + 1;
            end
            if (rise) n_rise = n_rise + 1;
            if (fall) n_fall = n_fall + 1;
            prev = d;
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 500; i = i + 1) begin
            @(negedge clk);
            d = ($unsigned($random(seed)) % 3 == 0) ? ~d : d;
        end
        @(negedge clk);
        $display("zboczy narastajacych %0d, opadajacych %0d", n_rise, n_fall);
        if (n_rise < 50 || n_fall < 50) begin $display("za malo zboczy"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #100000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
