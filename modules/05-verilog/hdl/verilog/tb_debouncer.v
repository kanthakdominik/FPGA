// Testbench eliminacji drgań: drgania krótsze niż STABLE_CYCLES nie zmieniają wyjścia,
// każda zmiana wyjścia następuje po co najmniej STABLE_CYCLES taktach stabilnego wejścia.
`default_nettype none
`timescale 1ns / 1ps

module tb_debouncer;
    localparam integer STABLE = 8;

    reg  clk = 1'b0, rst = 1'b1, noisy = 1'b0;
    wire clean, changed;

    always #5 clk = ~clk;

    debouncer #(.STABLE_CYCLES(STABLE)) dut (.clk(clk), .rst(rst), .noisy(noisy), .clean(clean), .changed(changed));

    integer errors = 0, k, run = 0, n_changes = 0;
    reg prev_clean = 1'b0;

    // jeden takt: ustaw wejście na opadającym zboczu i sprawdź wyjście
    task step(input v);
        begin
            @(negedge clk);
            if (changed) begin
                n_changes = n_changes + 1;
                if (run < STABLE) begin
                    $display("zmiana po %0d taktach stabilnego wejscia", run); errors = errors + 1;
                end
                if (clean === prev_clean) begin
                    $display("impuls changed bez zmiany clean"); errors = errors + 1;
                end
            end else if (clean !== prev_clean) begin
                $display("zmiana clean bez impulsu changed"); errors = errors + 1;
            end
            prev_clean = clean;
            run   = (v == noisy) ? run + 1 : 1;
            noisy = v;
        end
    endtask

    initial begin
        @(negedge clk); @(negedge clk);
        rst = 1'b0;
        // drgania przy wciśnięciu: zmiany co 1-3 takty
        for (k = 0; k < 12; k = k + 1) step(k % 3 != 0);
        for (k = 0; k < 20; k = k + 1) step(1'b1);
        if (clean !== 1'b1) begin
            $display("brak stanu 1 po stabilnym wejsciu"); errors = errors + 1;
        end
        // drgania przy puszczeniu
        for (k = 0; k < 12; k = k + 1) step(k % 4 == 1);
        for (k = 0; k < 20; k = k + 1) step(1'b0);
        if (clean !== 1'b0) begin
            $display("brak stanu 0 po stabilnym wejsciu"); errors = errors + 1;
        end
        if (n_changes != 2) begin
            $display("liczba zmian = %0d, oczekiwano 2", n_changes); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
