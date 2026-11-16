// Testbench: obie wersje addsel dają ten sam wynik co model a + (sel ? c : b).
// Wszystkie kombinacje dla W = 4 (2 * 16 * 16 * 16 = 8192 przypadki).
`timescale 1ns / 1ps

module tb_addsel;
    localparam int W = 4;

    logic         sel;
    logic [W-1:0] a, b, c;
    logic [W:0]   y2, y1;

    addsel_two_adders #(.W(W)) u_two (.sel, .a, .b, .c, .y(y2));
    addsel_one_adder  #(.W(W)) u_one (.sel, .a, .b, .c, .y(y1));

    int errors = 0;

    initial begin
        for (int s = 0; s < 2; s++)
            for (int i = 0; i < 2**W; i++)
                for (int j = 0; j < 2**W; j++)
                    for (int k = 0; k < 2**W; k++) begin
                        sel = 1'(s); a = W'(i); b = W'(j); c = W'(k); #1;
                        if (int'(y2) != (s ? i + k : i + j) || int'(y1) != (s ? i + k : i + j)) begin
                            $display("addsel: sel=%0d a=%0d b=%0d c=%0d y2=%0d y1=%0d", s, i, j, k, y2, y1);
                            errors++;
                        end
                    end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
