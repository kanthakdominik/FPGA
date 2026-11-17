// Porównanie RTL z netlistą dla full_case: losowe s (także 3) i dane.
`timescale 1ns / 1ps
`default_nettype none
module tb_full_case;
    reg [1:0] s = 2'd0;
    reg [7:0] a = 8'd0, b = 8'd0, c = 8'd0;
    wire [7:0] yz, yzn, yd, ydn;
    full_case_zle        u1 (.s(s), .a(a), .b(b), .c(c), .y(yz));
    full_case_zle_net    u2 (.s(s), .a(a), .b(b), .c(c), .y(yzn));
    full_case_dobrze     u3 (.s(s), .a(a), .b(b), .c(c), .y(yd));
    full_case_dobrze_net u4 (.s(s), .a(a), .b(b), .c(c), .y(ydn));
    integer i, rz = 0, rd = 0;
    initial begin
        for (i = 0; i < 200; i = i + 1) begin
            s = $random; a = $random; b = $random; c = $random;
            #5;
            if (yz !== yzn) rz = rz + 1;
            if (yd !== ydn) rd = rd + 1;
        end
        $display("ROZNICE zle=%0d dobrze=%0d", rz, rd);
        $finish;
    end
endmodule
`default_nettype wire
