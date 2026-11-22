// Testbench (SystemVerilog) zadania 4: oba automaty (Moore i Mealy) na tym samym losowym ciągu bitów z wtrąconymi wzorcami
// 1011 i 1011011 (nakładanie). Model: rejestr ostatnich bitów. Mealy: det w takcie ostatniego bitu wzorca,
// Moore: takt później.
`timescale 1ns / 1ps
`default_nettype none

module tb_seq_detect;
    logic  clk = 1'b0;
    logic  rst = 1'b1;
    logic  x = 1'b0;
    logic det_moore, det_mealy;
    always #5 clk = ~clk;

    seq_moore dut_moore (.clk(clk), .rst(rst), .x(x), .det(det_moore));
    seq_mealy dut_mealy (.clk(clk), .rst(rst), .x(x), .det(det_mealy));

    int   errors = 0, n_det = 0, i, j, seed = 7;
    logic [2:0] hist = 3'b000;
    logic       exp_mealy;
    logic       exp_moore = 1'b0;
    logic [6:0] wzor = 7'b1011011;

    always @(posedge clk)
        if (!rst) begin
            exp_mealy = ({hist, x} == 4'b1011);
            if (det_mealy !== exp_mealy || det_moore !== exp_moore) begin
                $display("%0t: x=%b ostatnie=%b mealy=%b (oczek. %b) moore=%b (oczek. %b)", $time, x, hist,
                         det_mealy, exp_mealy, det_moore, exp_moore);
                errors = errors + 1;
            end
            if (exp_mealy) n_det = n_det + 1;
            exp_moore = exp_mealy;
            hist = {hist[1:0], x};
        end

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 400; i = i + 1) begin
            if (i % 50 == 25)
                for (j = 6; j >= 0; j = j - 1) begin @(negedge clk); x = wzor[j]; end
            @(negedge clk);
            x = $random(seed);
        end
        @(negedge clk);
        @(negedge clk);
        $display("wykrytych wzorcow 1011: %0d", n_det);
        if (n_det < 20) begin $display("za malo wykryc"); errors = errors + 1; end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
    initial begin #100000; $display("FAIL: przekroczony czas"); $finish; end
endmodule

`default_nettype wire
