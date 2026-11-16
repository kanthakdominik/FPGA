// Testbench układów arytmetycznych: sumator pełny, sumator ripple-carry, sumator behawioralny, mnożarka.
// Wszystkie kombinacje wejść dla W = 4, porównanie z arytmetyką liczb całkowitych.
`timescale 1ns / 1ps

module tb_adders;
    localparam int W = 4;

    logic           fa_a, fa_b, fa_c, fa_s, fa_co;
    logic [W-1:0]   a, b, s_rca, s_beh;
    logic           cin, co_rca, co_beh;
    logic [2*W-1:0] p;

    full_adder         u_fa  (.a(fa_a), .b(fa_b), .cin(fa_c), .s(fa_s), .cout(fa_co));
    rca_adder #(.W(W)) u_rca (.a, .b, .cin, .s(s_rca), .cout(co_rca));
    adder     #(.W(W)) u_beh (.a, .b, .cin, .s(s_beh), .cout(co_beh));
    mult      #(.W(W)) u_mul (.a, .b, .p);

    int errors = 0;

    initial begin
        // sumator pełny: 8 kombinacji
        for (int i = 0; i < 8; i++) begin
            {fa_a, fa_b, fa_c} = 3'(i); #1;
            if (int'({fa_co, fa_s}) != int'(fa_a) + int'(fa_b) + int'(fa_c)) begin
                $display("full_adder: wejscie %0d -> %b%b", i, fa_co, fa_s); errors++;
            end
        end

        // sumatory i mnożarka: wszystkie a, b (i cin dla sumatorów)
        for (int c = 0; c < 2; c++)
            for (int i = 0; i < 2**W; i++)
                for (int j = 0; j < 2**W; j++) begin
                    a = W'(i); b = W'(j); cin = 1'(c); #1;
                    if (int'({co_rca, s_rca}) != i + j + c) begin
                        $display("rca_adder: %0d+%0d+%0d", i, j, c); errors++;
                    end
                    if (int'({co_beh, s_beh}) != i + j + c) begin
                        $display("adder: %0d+%0d+%0d", i, j, c); errors++;
                    end
                    if (int'(p) != i * j) begin
                        $display("mult: %0d*%0d = %0d", i, j, p); errors++;
                    end
                end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
