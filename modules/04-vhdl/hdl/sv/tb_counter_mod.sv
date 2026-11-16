// Testbench licznika modulo: porównanie z modelem w każdym takcie, zezwolenie przerywane, reset w trakcie pracy.
`timescale 1ns / 1ps

module tb_counter_mod;
    localparam int MODULO = 5;

    logic       clk = 1'b0;
    logic       rst = 1'b1;
    logic       en  = 1'b0;
    logic [2:0] count;
    logic       wrap;

    always #5 clk = ~clk;

    counter_mod #(.MODULO(MODULO)) dut (.*);

    int errors = 0, model = 0, wraps = 0;

    initial begin
        @(negedge clk);                            // pierwsze zbocze wykonało reset
        rst = 1'b0;
        for (int i = 0; i < 60; i++) begin
            if (count != model) begin
                $display("count=%0d oczekiwano %0d", count, model); errors++;
            end
            if (wrap != (en && model == MODULO - 1)) begin
                $display("zly wrap w takcie %0d", i); errors++;
            end
            if (wrap) wraps++;
            if (i == 40) begin
                rst = 1'b1; en = 1'b1; model = 0;
            end else begin
                rst = 1'b0;
                en  = (i % 4 != 3);
                if (en) model = (model + 1) % MODULO;
            end
            @(negedge clk);
        end
        if (wraps <= 5) begin
            $display("za malo przejsc przez MODULO - 1"); errors++;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
