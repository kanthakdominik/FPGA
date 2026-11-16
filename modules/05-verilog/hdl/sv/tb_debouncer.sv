// Testbench eliminacji drgań: drgania nie zmieniają wyjścia, zmiana następuje po
// co najmniej STABLE_CYCLES taktach stabilnego wejścia, dokładnie dwie zmiany w teście.
`timescale 1ns / 1ps

module tb_debouncer;
    localparam int STABLE = 8;

    logic clk = 1'b0, rst = 1'b1, noisy = 1'b0;
    logic clean, changed;

    always #5 clk = ~clk;

    debouncer #(.STABLE_CYCLES(STABLE)) dut (.*);

    int   errors = 0, run = 0, n_changes = 0;
    logic prev_clean = 1'b0;

    task automatic step(logic v);
        @(negedge clk);
        if (changed) begin
            n_changes++;
            if (run < STABLE) begin
                $display("zmiana po %0d taktach stabilnego wejscia", run); errors++;
            end
            if (clean == prev_clean) begin
                $display("impuls changed bez zmiany clean"); errors++;
            end
        end else if (clean != prev_clean) begin
            $display("zmiana clean bez impulsu changed"); errors++;
        end
        prev_clean = clean;
        run   = (v == noisy) ? run + 1 : 1;
        noisy = v;
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst = 1'b0;
        for (int k = 0; k < 12; k++) step(k % 3 != 0);     // drgania przy wciśnięciu
        repeat (20) step(1'b1);
        if (clean != 1'b1) begin
            $display("brak stanu 1 po stabilnym wejsciu"); errors++;
        end
        for (int k = 0; k < 12; k++) step(k % 4 == 1);     // drgania przy puszczeniu
        repeat (20) step(1'b0);
        if (clean != 1'b0) begin
            $display("brak stanu 0 po stabilnym wejsciu"); errors++;
        end
        if (n_changes != 2) begin
            $display("liczba zmian = %0d, oczekiwano 2", n_changes); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
