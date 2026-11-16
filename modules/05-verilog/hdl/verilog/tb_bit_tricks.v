// Testbench operacji bitowych: wszystkie 256 wartości, model z pętli po bitach.
`default_nettype none
`timescale 1ns / 1ps

module tb_bit_tricks;
    localparam integer W = 8;

    reg  [W-1:0] x;
    wire         is_pow2, parity, all_ones;
    wire [W-1:0] lowest, rev;

    bit_tricks #(.W(W)) dut (.x(x), .is_pow2(is_pow2), .lowest(lowest), .rev(rev), .parity(parity), .all_ones(all_ones));

    integer errors = 0, i, k, ones, low;
    reg [W-1:0] r;

    initial begin
        for (i = 0; i < (1 << W); i = i + 1) begin
            x = i; #1;
            ones = 0; low = 0;
            for (k = W - 1; k >= 0; k = k - 1) begin
                ones = ones + x[k];
                r[W-1-k] = x[k];
                if (x[k]) low = 1 << k;            // pętla od góry: zostaje najmłodsza jedynka
            end
            if (is_pow2 !== (ones == 1) || lowest !== low || rev !== r ||
                parity !== ones % 2 || all_ones !== (ones == W)) begin
                $display("x=%b: pow2=%b lowest=%b rev=%b par=%b all=%b", x, is_pow2, lowest, rev, parity, all_ones);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
