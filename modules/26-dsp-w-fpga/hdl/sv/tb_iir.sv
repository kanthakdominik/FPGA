// Testbench (SystemVerilog) 26.02: biquad_df2t (dolnoprzepustowy RBJ f0 = 0,02·fs, Q = 5, współczynniki Q2.14 z modelu) w trzech
// wariantach kwantyzacji. 2048 próbek z iir_we.hex (impuls, cisza, szum, cisza) — wyniki bit w bit z iir_wy0/1/2.hex.
// Pomiar: największe |y| w ciszy po impulsie (próbki 800..1023) i po szumie (1900..2047) — cykle graniczne.
`timescale 1ns / 1ps
`default_nettype none

module tb_iir;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [15:0] c_mem [0:4];
    logic  [15:0] x_mem [0:2047];
    logic  [15:0] w0_mem [0:2047];
    logic  [15:0] w1_mem [0:2047];
    logic  [15:0] w2_mem [0:2047];
    logic                we = 1'b0;
    logic  signed [15:0] x = 16'sd0;
    logic  signed [15:0] b0, b1, b2, a1, a2;
    logic signed [15:0] y0, y1, y2;
    logic               v0, v1, v2;
    biquad_df2t #(.ZAOKR(0)) u0 (.clk(clk), .rst(rst), .we(we), .x(x), .b0(b0), .b1(b1), .b2(b2), .a1(a1), .a2(a2), .y(y0), .y_wazne(v0));
    biquad_df2t #(.ZAOKR(1)) u1 (.clk(clk), .rst(rst), .we(we), .x(x), .b0(b0), .b1(b1), .b2(b2), .a1(a1), .a2(a2), .y(y1), .y_wazne(v1));
    biquad_df2t #(.ZAOKR(2)) u2 (.clk(clk), .rst(rst), .we(we), .x(x), .b0(b0), .b1(b1), .b2(b2), .a1(a1), .a2(a2), .y(y2), .y_wazne(v2));

    int n0 = 0, bl0 = 0, bl1 = 0, bl2 = 0, i;
    int c0a = 0, c1a = 0, c2a = 0, c0b = 0, c1b = 0, c2b = 0;
    function int absv(input signed [15:0] v);
        absv = (v < 0) ? -v : v;
    endfunction
    always @(posedge clk) if (!rst && v0) begin
        if (y0 !== w0_mem[n0]) begin if (bl0 < 5) $display("ZAOKR=0: probka %0d: %0d, model %0d", n0, y0, $signed(w0_mem[n0])); bl0 = bl0 + 1; end
        if (y1 !== w1_mem[n0]) begin if (bl1 < 5) $display("ZAOKR=1: probka %0d: %0d, model %0d", n0, y1, $signed(w1_mem[n0])); bl1 = bl1 + 1; end
        if (y2 !== w2_mem[n0]) begin if (bl2 < 5) $display("ZAOKR=2: probka %0d: %0d, model %0d", n0, y2, $signed(w2_mem[n0])); bl2 = bl2 + 1; end
        if (n0 >= 800 && n0 < 1024) begin
            if (absv(y0) > c0a) c0a = absv(y0);
            if (absv(y1) > c1a) c1a = absv(y1);
            if (absv(y2) > c2a) c2a = absv(y2);
        end
        if (n0 >= 1900) begin
            if (absv(y0) > c0b) c0b = absv(y0);
            if (absv(y1) > c1b) c1b = absv(y1);
            if (absv(y2) > c2b) c2b = absv(y2);
        end
        n0 = n0 + 1;
    end

    initial begin
        $readmemh("iir_wsp.hex", c_mem);
        $readmemh("iir_we.hex", x_mem);
        $readmemh("iir_wy0.hex", w0_mem);
        $readmemh("iir_wy1.hex", w1_mem);
        $readmemh("iir_wy2.hex", w2_mem);
        b0 = c_mem[0]; b1 = c_mem[1]; b2 = c_mem[2]; a1 = c_mem[3]; a2 = c_mem[4];
        $display("wspolczynniki Q2.14: b0 = %0d, b1 = %0d, b2 = %0d, a1 = %0d, a2 = %0d", b0, b1, b2, a1, a2);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 2048; i = i + 1) begin
            @(negedge clk);
            x = x_mem[i]; we = 1'b1;
        end
        @(negedge clk) we = 1'b0;
        repeat (5) @(negedge clk);
        $display("ZAOKR=0 (obciecie):       niezgodnych %0d; max |y| po impulsie %0d, po szumie %0d", bl0, c0a, c0b);
        $display("ZAOKR=1 (zaokraglenie):   niezgodnych %0d; max |y| po impulsie %0d, po szumie %0d", bl1, c1a, c1b);
        $display("ZAOKR=2 (w strone zera):  niezgodnych %0d; max |y| po impulsie %0d, po szumie %0d", bl2, c2a, c2b);
        if (n0 != 2048 || bl0 != 0 || bl1 != 0 || bl2 != 0) errors = errors + 1;
        if (c2a != 0 || c2b != 0) errors = errors + 1;                 // obcięcie w stronę zera: brak cykli
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
