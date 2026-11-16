// Testbench licznika kredytów: losowe, poprawne operacje take/give porównane z modelem.
// Asercje w układzie nie powinny się odezwać — testbench przestrzega reguł protokołu.
`timescale 1ns / 1ps

module tb_credit_counter;
    localparam int MAX = 4;

    logic       clk = 1'b0, rst = 1'b1, take = 1'b0, give = 1'b0;
    logic [2:0] credits;
    logic       can_take;

    always #5 clk = ~clk;

    credit_counter #(.MAX(MAX)) dut (.*);

    int errors = 0, n_zero = 0, n_full = 0;

    initial begin
        int         model = MAX;
        logic [7:0] lfsr  = 8'h5D;
        @(negedge clk);
        rst = 1'b0;
        for (int k = 0; k < 300; k++) begin
            if (int'(credits) != model || can_take != (model != 0)) begin
                $display("takt %0d: credits=%0d, model %0d", k, credits, model); errors++;
            end
            n_zero += (model == 0);
            n_full += (model == MAX);
            lfsr = lfsr[0] ? ((lfsr >> 1) ^ 8'hB8) : (lfsr >> 1);
            // faza 1: głównie pobieranie (dojście do 0), faza 2: głównie oddawanie (do MAX), faza 3: losowo
            take = (k < 100 ? (lfsr[0] | lfsr[2]) : k < 200 ? (lfsr[0] & lfsr[2]) : lfsr[0]) && (model > 0);
            give = (k < 100 ? (lfsr[1] & lfsr[3]) : k < 200 ? (lfsr[1] | lfsr[3]) : lfsr[1]) && (model < MAX || take);
            if (take && !give) model--;
            if (give && !take) model++;
            @(negedge clk);
        end
        if (n_zero == 0 || n_full == 0) begin
            $display("test nie osiagnal stanow brzegowych (0: %0d, MAX: %0d)", n_zero, n_full); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
