// Testbench dekodera 7-segmentowego. Model zapisany inaczej niż układ:
// dla każdego segmentu maska cyfr, przy których świeci (bit d maski = cyfra d).
`default_nettype none
`timescale 1ns / 1ps

module tb_seg7_decoder;
    reg  [3:0] hex;
    wire [6:0] seg;

    seg7_decoder dut (.hex(hex), .seg(seg));

    //                           g         f         e         d         c         b         a
    localparam [16*7-1:0] MASK = {16'hEF7C, 16'hDF71, 16'hFD45, 16'h7B6D, 16'h2FFB, 16'h279F, 16'hD7ED};

    integer errors = 0, d, s;

    initial begin
        for (d = 0; d < 16; d = d + 1) begin
            hex = d; #1;
            for (s = 0; s < 7; s = s + 1)
                if (seg[s] !== MASK[s*16 + d]) begin
                    $display("cyfra %0d, segment %0d", d, s); errors = errors + 1;
                end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
