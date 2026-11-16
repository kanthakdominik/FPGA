// Testbench układów arytmetycznych: sumator pełny, sumator ripple-carry, sumator behawioralny, mnożarka.
// Wszystkie kombinacje wejść dla W = 4, porównanie z arytmetyką liczb całkowitych.
`default_nettype none
`timescale 1ns / 1ps

module tb_adders;
    localparam integer W = 4;

    reg          fa_a, fa_b, fa_c;
    wire         fa_s, fa_co;
    reg  [W-1:0] a, b;
    reg          cin;
    wire [W-1:0] s_rca, s_beh;
    wire         co_rca, co_beh;
    wire [2*W-1:0] p;

    full_adder           u_fa  (.a(fa_a), .b(fa_b), .cin(fa_c), .s(fa_s), .cout(fa_co));
    rca_adder #(.W(W))   u_rca (.a(a), .b(b), .cin(cin), .s(s_rca), .cout(co_rca));
    adder     #(.W(W))   u_beh (.a(a), .b(b), .cin(cin), .s(s_beh), .cout(co_beh));
    mult      #(.W(W))   u_mul (.a(a), .b(b), .p(p));

    integer errors, i, j, c, suma;

    initial begin
        errors = 0;

        // sumator pełny: 8 kombinacji
        for (i = 0; i < 8; i = i + 1) begin
            {fa_a, fa_b, fa_c} = i; #1;
            suma = fa_a + fa_b + fa_c;
            if ({fa_co, fa_s} !== suma[1:0]) begin
                $display("full_adder: wejscie %b -> %b%b", i[2:0], fa_co, fa_s); errors = errors + 1;
            end
        end

        // sumatory i mnożarka: wszystkie a, b (i cin dla sumatorów)
        for (c = 0; c < 2; c = c + 1)
            for (i = 0; i < (1 << W); i = i + 1)
                for (j = 0; j < (1 << W); j = j + 1) begin
                    a = i; b = j; cin = c; #1;
                    suma = i + j + c;
                    if ({co_rca, s_rca} !== suma[W:0]) begin
                        $display("rca_adder: %0d+%0d+%0d", i, j, c); errors = errors + 1;
                    end
                    if ({co_beh, s_beh} !== suma[W:0]) begin
                        $display("adder: %0d+%0d+%0d", i, j, c); errors = errors + 1;
                    end
                    if (p !== i * j) begin
                        $display("mult: %0d*%0d = %0d", i, j, p); errors = errors + 1;
                    end
                end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
