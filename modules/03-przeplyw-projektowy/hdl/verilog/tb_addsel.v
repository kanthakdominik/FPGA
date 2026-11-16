// Testbench: obie wersje addsel dają ten sam wynik co model a + (sel ? c : b).
// Wszystkie kombinacje dla W = 4 (2 * 16 * 16 * 16 = 8192 przypadki).
`default_nettype none
`timescale 1ns / 1ps

module tb_addsel;
    localparam integer W = 4;

    reg          sel;
    reg  [W-1:0] a, b, c;
    wire [W:0]   y2, y1;

    addsel_two_adders #(.W(W)) u_two (.sel(sel), .a(a), .b(b), .c(c), .y(y2));
    addsel_one_adder  #(.W(W)) u_one (.sel(sel), .a(a), .b(b), .c(c), .y(y1));

    integer errors, s, i, j, k, expect;

    initial begin
        errors = 0;
        for (s = 0; s < 2; s = s + 1)
            for (i = 0; i < (1 << W); i = i + 1)
                for (j = 0; j < (1 << W); j = j + 1)
                    for (k = 0; k < (1 << W); k = k + 1) begin
                        sel = s; a = i; b = j; c = k; #1;
                        expect = s ? i + k : i + j;
                        if (y2 !== expect[W:0] || y1 !== expect[W:0]) begin
                            $display("addsel: sel=%0d a=%0d b=%0d c=%0d y2=%0d y1=%0d", s, i, j, k, y2, y1);
                            errors = errors + 1;
                        end
                    end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
