// Testbench licznika modulo: porównanie z modelem w każdym takcie, zezwolenie przerywane, reset w trakcie pracy.
`default_nettype none
`timescale 1ns / 1ps

module tb_counter_mod;
    localparam integer MODULO = 5;

    reg        clk = 1'b0;
    reg        rst = 1'b1;
    reg        en  = 1'b0;
    wire [2:0] count;
    wire       wrap;

    always #5 clk = ~clk;

    counter_mod #(.MODULO(MODULO)) dut (.clk(clk), .rst(rst), .en(en), .count(count), .wrap(wrap));

    integer errors = 0, model = 0, wraps = 0, i;

    initial begin
        @(negedge clk);                            // pierwsze zbocze wykonało reset
        rst = 1'b0;
        for (i = 0; i < 60; i = i + 1) begin
            if (count !== model) begin
                $display("count=%0d oczekiwano %0d", count, model); errors = errors + 1;
            end
            if (wrap !== (en && model == MODULO - 1)) begin
                $display("zly wrap w takcie %0d", i); errors = errors + 1;
            end
            if (wrap) wraps = wraps + 1;
            if (i == 40) begin
                rst = 1'b1; en = 1'b1; model = 0;
            end else begin
                rst = 1'b0;
                if (i % 4 == 3) en = 1'b0;
                else begin
                    en = 1'b1; model = (model + 1) % MODULO;
                end
            end
            @(negedge clk);
        end
        if (wraps <= 5) begin
            $display("za malo przejsc przez MODULO - 1"); errors = errors + 1;
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
