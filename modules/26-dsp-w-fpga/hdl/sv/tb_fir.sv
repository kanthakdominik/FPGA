// Testbench (SystemVerilog) 26.01: fir_transp i fir_sym (N = 31, dolnoprzepustowy fc = 0,1·fs, współczynniki z model/dsp_model.py).
// 2048 próbek z fir_we.hex (impuls, skok, szum, chirp) podawanych z przerwami (we nie w każdym takcie);
// wyniki obu filtrów porównane bit w bit z fir_wy.hex (model Pythona). Mierzy opóźnienie obu struktur.
`timescale 1ns / 1ps
`default_nettype none

module tb_fir;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [15:0] h_mem [0:30];
    logic  [15:0] x_mem [0:2047];
    logic  [15:0] y_mem [0:2047];
    logic  [16*31-1:0] wsp;
    logic                we = 1'b0;
    logic  signed [15:0] x = 16'sd0;
    logic signed [15:0] yt, ys;
    logic               vt, vs;
    fir_transp #(.N(31)) u_t (.clk(clk), .rst(rst), .we(we), .x(x), .wsp(wsp), .y(yt), .y_wazne(vt));
    fir_sym    #(.N(31)) u_s (.clk(clk), .rst(rst), .we(we), .x(x), .wsp(wsp), .y(ys), .y_wazne(vs));

    int nt = 0, ns = 0, bt = 0, bs = 0, i, t0 = -1, lt = -1, ls = -1, takt = 0;
    always @(posedge clk) takt <= takt + 1;
    always @(posedge clk) if (!rst) begin
        if (vt) begin
            if (yt !== y_mem[nt]) begin
                if (bt < 5) $display("fir_transp: probka %0d: %0d, model %0d", nt, yt, $signed(y_mem[nt]));
                bt = bt + 1;
            end
            if (nt == 0) lt = takt - t0;
            nt = nt + 1;
        end
        if (vs) begin
            if (ys !== y_mem[ns]) begin
                if (bs < 5) $display("fir_sym: probka %0d: %0d, model %0d", ns, ys, $signed(y_mem[ns]));
                bs = bs + 1;
            end
            if (ns == 0) ls = takt - t0;
            ns = ns + 1;
        end
    end

    initial begin
        $readmemh("fir_wsp.hex", h_mem);
        $readmemh("fir_we.hex", x_mem);
        $readmemh("fir_wy.hex", y_mem);
        for (i = 0; i < 31; i = i + 1) wsp[16*i +: 16] = h_mem[i];
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 2048; i = i + 1) begin
            @(negedge clk);
            x = x_mem[i]; we = 1'b1;
            if (i == 0) t0 = takt;
            if (i % 7 == 6) begin @(negedge clk) we = 1'b0; end      // co siódma próbka — takt przerwy
        end
        @(negedge clk) we = 1'b0;
        repeat (20) @(negedge clk);
        $display("fir_transp: %0d probek, niezgodnych z modelem %0d, opoznienie %0d takt(y)", nt, bt, lt);
        $display("fir_sym:    %0d probek, niezgodnych z modelem %0d, opoznienie %0d takt(y)", ns, bs, ls);
        if (nt != 2048 || ns != 2048 || bt != 0 || bs != 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
