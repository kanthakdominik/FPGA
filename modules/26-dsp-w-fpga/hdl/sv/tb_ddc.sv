// Testbench (SystemVerilog) 26.06: ddc. Sygnał rzeczywisty 20000·cos(2π·0,105·n) (ddc_we.hex), nośna NCO 0,1·fs (ftw 0x1999999A),
// próbka w każdym takcie. I/Q po decymacji przez 8 bit w bit z ddc_wy.hex. Pomiar: |I + jQ| w stanie ustalonym
// (ton przesunięty do 0,005·fs, czyli 0,04·fs po decymacji).
`timescale 1ns / 1ps
`default_nettype none

module tb_ddc;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [15:0] x_mem [0:4095];
    logic  [31:0] y_mem [0:511];
    logic                we = 1'b0;
    logic  signed [15:0] x = 16'sd0;
    logic signed [15:0] wi, wq;
    logic               v;
    ddc u_ddc (.clk(clk), .rst(rst), .we(we), .x(x), .ftw(32'h1999999A), .i_wy(wi), .q_wy(wq), .wy_wazne(v));

    int n = 0, bl = 0, i;
    real    amin = 1.0e9, amax = 0.0, a;
    always @(posedge clk) if (!rst && v) begin
        if ({wi, wq} !== y_mem[n]) begin
            if (bl < 5) $display("probka %0d: (%0d, %0d), model (%0d, %0d)", n, wi, wq, $signed(y_mem[n][31:16]), $signed(y_mem[n][15:0]));
            bl = bl + 1;
        end
        if (n >= 16) begin
            a = $sqrt(1.0 * wi * wi + 1.0 * wq * wq);
            if (a > amax) amax = a;
            if (a < amin) amin = a;
        end
        n = n + 1;
    end

    initial begin
        $readmemh("ddc_we.hex", x_mem);
        $readmemh("ddc_wy.hex", y_mem);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 4096; i = i + 1) begin
            @(negedge clk) begin x = x_mem[i]; we = 1'b1; end
        end
        @(negedge clk) we = 1'b0;
        repeat (20) @(negedge clk);
        $display("ddc: %0d probek I/Q, niezgodnych z modelem %0d; |I+jQ| od %0.1f do %0.1f", n, bl, amin, amax);
        if (n != 512 || bl != 0) errors = errors + 1;
        if (amin < 9000.0 || amax > 11000.0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
