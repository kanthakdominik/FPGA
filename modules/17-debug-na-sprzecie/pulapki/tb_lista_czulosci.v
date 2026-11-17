// Porównanie RTL z netlistą po syntezie (Yosys) dla lista_czulosci: a i b zmieniają się niezależnie.
`timescale 1ns / 1ps
`default_nettype none
module tb_lista_czulosci;
    reg  [7:0] a = 8'd0, b = 8'd0;
    wire [7:0] yz, yzn, yd, ydn;
    lista_czulosci_zle        u1 (.a(a), .b(b), .y(yz));
    lista_czulosci_zle_net    u2 (.a(a), .b(b), .y(yzn));
    lista_czulosci_dobrze     u3 (.a(a), .b(b), .y(yd));
    lista_czulosci_dobrze_net u4 (.a(a), .b(b), .y(ydn));
    integer i, rz = 0, rd = 0;
    initial begin
        for (i = 0; i < 200; i = i + 1) begin
            if (i % 2) a = $random; else b = $random;
            #5;
            if (yz !== yzn) rz = rz + 1;
            if (yd !== ydn) rd = rd + 1;
        end
        $display("ROZNICE zle=%0d dobrze=%0d", rz, rd);
        $finish;
    end
endmodule
`default_nettype wire
