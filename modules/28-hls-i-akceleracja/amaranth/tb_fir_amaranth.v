// Testbench 28.06: Verilog wygenerowany przez Amaranth (fir_amaranth.v) na wektorach modułu 26 — ten sam test
// co tb_fir dla ręcznego fir_transp: 2048 próbek bit w bit. Uruchomienie: make -C amaranth (wymaga Amaranth).
`timescale 1ns / 1ps
`default_nettype none

module tb_fir_amaranth;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;

    reg  [15:0] x_mem [0:2047];
    reg  [15:0] y_mem [0:2047];
    reg                we = 1'b0;
    reg  signed [15:0] x = 16'sd0;
    wire signed [15:0] y;
    wire               y_wazne;
    fir_amaranth dut (.clk(clk), .rst(rst), .we(we), .x(x), .y(y), .y_wazne(y_wazne));

    integer n = 0, bl = 0, i;
    always @(posedge clk) if (!rst && y_wazne) begin
        if (y !== y_mem[n]) begin
            if (bl < 5) $display("probka %0d: %0d, model %0d", n, y, $signed(y_mem[n]));
            bl = bl + 1;
        end
        n = n + 1;
    end

    initial begin
        $readmemh("../../26-dsp-w-fpga/hdl/dane/fir_we.hex", x_mem);
        $readmemh("../../26-dsp-w-fpga/hdl/dane/fir_wy.hex", y_mem);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 2048; i = i + 1) begin
            @(negedge clk);
            x = x_mem[i]; we = 1'b1;
        end
        @(negedge clk) we = 1'b0;
        repeat (5) @(negedge clk);
        $display("fir_amaranth (Verilog z Amaranth, Icarus): %0d probek, niezgodnych z modelem %0d", n, bl);
        if (n == 2048 && bl == 0) $display("PASS");
        else                      $display("FAIL");
        $finish;
    end
endmodule

`default_nettype wire
