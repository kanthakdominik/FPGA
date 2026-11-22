// Testbench zadania 12: najpierw impuls (x = 1, potem zera) — na wyjściu kolejne współczynniki h; potem stała
// 1000 (wyjście 256 000 po 8 próbkach); potem 2000 losowych próbek z pełnego zakresu z losowym en. Model:
// splot z ostatnimi 8 próbkami, porównanie po każdej próbce.
`timescale 1ns / 1ps
`default_nettype none

module tb_fir_transposed;
    reg                clk = 1'b0;
    reg                rst = 1'b1;
    reg                en = 1'b0;
    reg  signed [11:0] x = 12'sd0;
    wire signed [23:0] y;
    always #5 clk = ~clk;

    fir_transposed dut (.clk(clk), .rst(rst), .en(en), .x(x), .y(y));

    integer h [0:7];
    integer hist [0:7];
    integer errors = 0, n = 0, i, k, exp_y = 0, seed = 6, y_max = 0;
    reg     check = 1'b0;

    initial begin
        h[0] = 2; h[1] = -10; h[2] = 40; h[3] = 96; h[4] = 96; h[5] = 40; h[6] = -10; h[7] = 2;
        for (k = 0; k < 8; k = k + 1) hist[k] = 0;
    end

    always @(posedge clk)
        if (!rst && en) begin
            for (k = 7; k > 0; k = k - 1) hist[k] = hist[k - 1];
            hist[0] = x;
            exp_y = 0;
            for (k = 0; k < 8; k = k + 1) exp_y = exp_y + h[k] * hist[k];
            check = 1'b1;
            n = n + 1;
        end

    always @(negedge clk)
        if (check) begin
            if (y !== exp_y) begin $display("%0t: y=%0d, oczekiwano %0d", $time, y, exp_y); errors = errors + 1; end
            if (exp_y > y_max) y_max = exp_y;
            if (-exp_y > y_max) y_max = -exp_y;
            check = 1'b0;
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        // odpowiedź impulsowa
        @(negedge clk); en = 1'b1; x = 12'sd1;
        for (i = 1; i < 8; i = i + 1) begin
            @(negedge clk); x = 12'sd0;
            if (y !== h[i - 1]) begin $display("impuls: y[%0d]=%0d, oczekiwano %0d", i - 1, y, h[i - 1]); errors = errors + 1; end
        end
        // stała 1000: po 8 próbkach 1000 * 256
        for (i = 0; i < 10; i = i + 1) begin @(negedge clk); x = 12'sd1000; end
        @(negedge clk);
        if (y !== 256000) begin $display("stala: y=%0d, oczekiwano 256000", y); errors = errors + 1; end
        // losowo
        for (i = 0; i < 2000; i = i + 1) begin
            @(negedge clk);
            en = ($unsigned($random(seed)) % 4 != 0);
            x  = (i % 200 < 20) ? ((i % 2) ? 12'sh7FF : 12'sh800) : $random(seed);
        end
        @(negedge clk) en = 1'b0;
        @(negedge clk);
        $display("probek %0d, najwiekszy |y| = %0d (zakres 24 bitow: 8388607)", n, y_max);
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #200000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
