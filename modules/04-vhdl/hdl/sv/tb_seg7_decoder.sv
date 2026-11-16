// Testbench dekodera 7-segmentowego. Model zapisany inaczej niż układ:
// dla każdego segmentu maska cyfr, przy których świeci (bit d maski = cyfra d).
`timescale 1ns / 1ps

module tb_seg7_decoder;
    logic [3:0] hex;
    logic [6:0] seg;

    seg7_decoder dut (.*);

    //                                    a        b        c        d        e        f        g
    localparam logic [15:0] MASK [7] = '{16'hD7ED, 16'h279F, 16'h2FFB, 16'h7B6D, 16'hFD45, 16'hDF71, 16'hEF7C};

    int errors = 0;

    initial begin
        for (int d = 0; d < 16; d++) begin
            hex = 4'(d); #1;
            for (int s = 0; s < 7; s++)
                if (seg[s] != MASK[s][d]) begin
                    $display("cyfra %0d, segment %0d", d, s); errors++;
                end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule
