// Porównanie RTL z netlistą dla x_optymizm: reset jest podany, ale rejestr wyboru wersji "zle" go
// nie używa; przez pierwsze 100 taktów nic nie ładuje rejestru wyboru (wartość X w symulacji).
`timescale 1ns / 1ps
`default_nettype none
module tb_x_optymizm;
    reg clk = 1'b0, rst = 1'b1, load = 1'b0, sel_in = 1'b0;
    reg [7:0] a = 8'd0, b = 8'd0;
    always #5 clk = ~clk;
    wire [7:0] yz, yzn, yd, ydn;
    x_optymizm_zle        u1 (.clk(clk), .rst(rst), .load(load), .sel_in(sel_in), .a(a), .b(b), .y(yz));
    x_optymizm_zle_net    u2 (.clk(clk), .rst(rst), .load(load), .sel_in(sel_in), .a(a), .b(b), .y(yzn));
    x_optymizm_dobrze     u3 (.clk(clk), .rst(rst), .load(load), .sel_in(sel_in), .a(a), .b(b), .y(yd));
    x_optymizm_dobrze_net u4 (.clk(clk), .rst(rst), .load(load), .sel_in(sel_in), .a(a), .b(b), .y(ydn));
    integer i, rz = 0, rd = 0;
    initial begin
        for (i = 0; i < 200; i = i + 1) begin
            @(negedge clk);
            if (i > 3) begin
                if (yz !== yzn) rz = rz + 1;
                if (yd !== ydn) rd = rd + 1;
            end
            if (i == 2) rst = 1'b0;
            a = $random;
            b = $random;
            load = (i > 100) && ($random % 4 == 0);
            sel_in = $random;
        end
        $display("ROZNICE zle=%0d dobrze=%0d", rz, rd);
        $finish;
    end
endmodule
`default_nettype wire
