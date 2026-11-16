// Testbench mac: wektory losowej długości (1..8) z przerwami w in_valid, wartości skrajne (-256),
// model — suma iloczynów liczb całkowitych, wyniki w kolejce porównane po 3 taktach.
`timescale 1ns / 1ps

module tb_mac;
    logic               clk = 1'b0, rst = 1'b1, in_valid = 1'b0, first = 1'b0, acc_valid;
    logic signed [8:0]  a = '0, b = '0;
    logic signed [23:0] acc;

    always #5 clk = ~clk;

    mac #(.W(9), .ACC_W(24)) dut (.*);

    int exp_q [$];
    int errors = 0, checked = 0, pushed = 0, extremes = 0, sum = 0;

    task automatic step();                     // jeden takt: sprawdzenie wyjścia, potem nowe wejścia
        @(negedge clk);
        if (acc_valid) begin
            if (exp_q.size() == 0) begin
                $display("acc_valid bez oczekiwanego wyniku"); errors++;
            end else begin
                int e = exp_q.pop_front();
                if (int'(acc) != e) begin
                    $display("wynik %0d: acc=%0d, oczekiwano %0d", checked, acc, e); errors++;
                end
            end
            checked++;
        end
    endtask

    function automatic logic signed [8:0] sample();
        return ($urandom_range(7) == 0) ? 9'sh100 : 9'($urandom);
    endfunction

    initial begin
        step(); step();
        rst = 1'b0;
        for (int v = 0; v < 60; v++) begin
            int len, s;
            len = 1 + $urandom_range(7);       // zmienne bloku są statyczne: wartość nadana jawnie w każdym obiegu
            s   = 0;
            while (s < len) begin
                in_valid = ($urandom_range(3) != 0);
                if (in_valid) begin
                    first = (s == 0);
                    a = sample();
                    b = sample();
                    if (a == -256 && b == -256) extremes++;
                    sum = (first ? 0 : sum) + int'(a) * int'(b);
                    exp_q.push_back(sum);
                    pushed++;
                    s++;
                end
                step();
            end
        end
        in_valid = 1'b0;
        repeat (5) step();

        if (checked != pushed) begin
            $display("sprawdzono %0d z %0d wynikow", checked, pushed); errors++;
        end
        if (extremes == 0) begin
            $display("test nie sprawdzil iloczynu (-256) * (-256)"); errors++;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
