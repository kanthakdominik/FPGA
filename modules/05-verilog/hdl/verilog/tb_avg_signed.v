// Testbench średniej ze znakiem: wszystkie pary liczb 4-bitowych, model floor((a + b) / 2).
`default_nettype none
`timescale 1ns / 1ps

module tb_avg_signed;
    localparam integer W = 4;

    reg  signed [W-1:0] a, b;
    wire signed [W-1:0] y;

    avg_signed #(.W(W)) dut (.a(a), .b(b), .y(y));

    integer errors = 0, i, j, s, e;

    initial begin
        for (i = -8; i <= 7; i = i + 1)
            for (j = -8; j <= 7; j = j + 1) begin
                a = i; b = j; #1;
                s = i + j;
                // dzielenie całkowite w Verilogu zaokrągla do zera — poprawka dla nieparzystych ujemnych
                e = (s >= 0 || s % 2 == 0) ? s / 2 : s / 2 - 1;
                if (y != e) begin
                    $display("avg(%0d, %0d) = %0d, oczekiwano %0d", i, j, y, e); errors = errors + 1;
                end
            end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
