// Testbench mac: wektory losowej długości (1..8) z przerwami w in_valid, wartości skrajne (-256 = 9'h100),
// model — suma iloczynów liczb całkowitych, wyniki zapamiętane w kolejce i porównane po 3 taktach.
`default_nettype none
`timescale 1ns / 1ps

module tb_mac;
    reg               clk = 1'b0, rst = 1'b1, in_valid = 1'b0, first = 1'b0;
    reg  signed [8:0] a = 9'sd0, b = 9'sd0;
    wire signed [23:0] acc;
    wire              acc_valid;

    always #5 clk = ~clk;

    mac #(.W(9), .ACC_W(24)) dut (.clk(clk), .rst(rst), .in_valid(in_valid), .first(first),
                                  .a(a), .b(b), .acc(acc), .acc_valid(acc_valid));

    integer exp_q [0:1023];
    integer errors = 0, wr = 0, rd = 0, v, len, s, sum = 0, extremes = 0, seed = 21;

    task step;                                 // jeden takt: sprawdzenie wyjścia, potem nowe wejścia
        begin
            @(negedge clk);
            if (acc_valid) begin
                if (rd >= wr) begin
                    $display("acc_valid bez oczekiwanego wyniku"); errors = errors + 1;
                end else if (acc !== exp_q[rd]) begin
                    $display("wynik %0d: acc=%0d, oczekiwano %0d", rd, acc, exp_q[rd]); errors = errors + 1;
                end
                rd = rd + 1;
            end
        end
    endtask

    initial begin
        step; step;
        rst = 1'b0;
        for (v = 0; v < 60; v = v + 1) begin
            len = 1 + (($random(seed) & 32'h7fffffff) % 8);
            s   = 0;
            while (s < len) begin
                in_valid = (($random(seed) & 3) != 0);
                if (in_valid) begin
                    first = (s == 0);
                    a = ($random(seed) % 8 == 0) ? 9'h100 : $random(seed);
                    b = ($random(seed) % 8 == 0) ? 9'h100 : $random(seed);
                    if (a == -256 && b == -256) extremes = extremes + 1;
                    sum = (first ? 0 : sum) + a * b;
                    exp_q[wr] = sum;
                    wr = wr + 1;
                    s  = s + 1;
                end
                step;
            end
        end
        in_valid = 1'b0;
        repeat (5) step;

        if (rd != wr) begin
            $display("sprawdzono %0d z %0d wynikow", rd, wr); errors = errors + 1;
        end
        if (extremes == 0) begin
            $display("test nie sprawdzil iloczynu (-256) * (-256)"); errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
