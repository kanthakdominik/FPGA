// Porównanie RTL z netlistą dla opoznienia: zegar 10 ns, nowe dane w każdym takcie, odczyt na opadającym zboczu.
`timescale 1ns / 1ps
`default_nettype none
module tb_opoznienia;
    reg clk = 1'b0;
    reg [7:0] d = 8'd0;
    always #5 clk = ~clk;
    wire [7:0] qz, qzn, qd, qdn;
    opoznienia_zle        u1 (.clk(clk), .d(d), .q(qz));
    opoznienia_zle_net    u2 (.clk(clk), .d(d), .q(qzn));
    opoznienia_dobrze     u3 (.clk(clk), .d(d), .q(qd));
    opoznienia_dobrze_net u4 (.clk(clk), .d(d), .q(qdn));
    integer i, rz = 0, rd = 0;
    initial begin
        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            if (i > 3) begin
                if (qz !== qzn) rz = rz + 1;
                if (qd !== qdn) rd = rd + 1;
            end
            d = $random;
        end
        $display("ROZNICE zle=%0d dobrze=%0d", rz, rd);
        $finish;
    end
endmodule
`default_nettype wire
