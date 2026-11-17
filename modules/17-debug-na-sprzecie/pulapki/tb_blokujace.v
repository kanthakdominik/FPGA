// Porównanie RTL z netlistą dla blokujace: załadowanie dwóch różnych wartości, potem wymiana w każdym takcie.
`timescale 1ns / 1ps
`default_nettype none
module tb_blokujace;
    reg clk = 1'b0, load = 1'b0;
    reg [7:0] da = 8'd0, db = 8'd0;
    always #5 clk = ~clk;
    wire [7:0] az, bz, azn, bzn, ad, bd, adn, bdn;
    blokujace_zle        u1 (.clk(clk), .load(load), .da(da), .db(db), .a(az),  .b(bz));
    blokujace_zle_net    u2 (.clk(clk), .load(load), .da(da), .db(db), .a(azn), .b(bzn));
    blokujace_dobrze     u3 (.clk(clk), .load(load), .da(da), .db(db), .a(ad),  .b(bd));
    blokujace_dobrze_net u4 (.clk(clk), .load(load), .da(da), .db(db), .a(adn), .b(bdn));
    integer i, rz = 0, rd = 0;
    initial begin
        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            if (i > 1) begin
                if (az !== azn || bz !== bzn) rz = rz + 1;
                if (ad !== adn || bd !== bdn) rd = rd + 1;
            end
            load = (i % 20 == 0);
            da = $random;
            db = $random;
        end
        $display("ROZNICE zle=%0d dobrze=%0d", rz, rd);
        $finish;
    end
endmodule
`default_nettype wire
