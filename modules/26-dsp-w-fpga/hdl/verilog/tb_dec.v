// Testbench 26.04: cic_dec (N = 3, R = 8) i pf_dec (FIR 32 współczynniki, decymacja przez 4).
// 4096 próbek z dec_we.hex (skok, szum, dwa tony 0,01·fs i 0,3·fs), jedna co 16 taktów; wyniki bit w bit
// z cic_wy.hex (512 próbek) i pfd_wy.hex (1024 próbki). Pomiar: amplituda tonu 0,3·fs po obu decymatorach.
`timescale 1ns / 1ps
`default_nettype none

module tb_dec;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0;

    reg  [15:0] x_mem [0:4095];
    reg  [15:0] c_mem [0:511];
    reg  [15:0] h_mem [0:31];
    reg  [15:0] p_mem [0:1023];
    reg  [16*32-1:0] wsp;
    reg                we = 1'b0;
    reg  signed [15:0] x = 16'sd0;
    wire signed [15:0] yc, yp;
    wire               vc, vp;
    cic_dec #(.R(8))  u_cic (.clk(clk), .rst(rst), .we(we), .x(x), .y(yc), .y_wazne(vc));
    pf_dec  #(.N(32)) u_pf  (.clk(clk), .rst(rst), .we(we), .x(x), .wsp(wsp), .y(yp), .y_wazne(vp));

    integer nc = 0, np = 0, bc = 0, bp = 0, i;
    integer cmin = 0, cmax = 0, pmin = 0, pmax = 0;
    always @(posedge clk) if (!rst) begin
        if (vc) begin
            if (yc !== c_mem[nc]) begin if (bc < 5) $display("cic: probka %0d: %0d, model %0d", nc, yc, $signed(c_mem[nc])); bc = bc + 1; end
            if (nc >= 300) begin if (yc > cmax) cmax = yc; if (yc < cmin) cmin = yc; end
            nc = nc + 1;
        end
        if (vp) begin
            if (yp !== p_mem[np]) begin if (bp < 5) $display("pf_dec: probka %0d: %0d, model %0d", np, yp, $signed(p_mem[np])); bp = bp + 1; end
            if (np >= 600) begin if (yp > pmax) pmax = yp; if (yp < pmin) pmin = yp; end
            np = np + 1;
        end
    end

    initial begin
        $readmemh("dec_we.hex", x_mem);
        $readmemh("cic_wy.hex", c_mem);
        $readmemh("pfd_wsp.hex", h_mem);
        $readmemh("pfd_wy.hex", p_mem);
        for (i = 0; i < 32; i = i + 1) wsp[16*i +: 16] = h_mem[i];
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 4096; i = i + 1) begin
            @(negedge clk) begin x = x_mem[i]; we = 1'b1; end
            @(negedge clk) we = 1'b0;
            repeat (14) @(negedge clk);
        end
        repeat (60) @(negedge clk);
        $display("cic_dec: %0d probek, niezgodnych %0d; tony po decymacji: %0d..%0d", nc, bc, cmin, cmax);
        $display("pf_dec:  %0d probek, niezgodnych %0d; tony po decymacji: %0d..%0d", np, bp, pmin, pmax);
        if (nc != 512 || np != 1024 || bc != 0 || bp != 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
