// Testbench (SystemVerilog) 26.03: nco i sd_dac.
//  - nco: 4096 próbek dla czterech słów ftw (1024 każde: 0,005·fs, 0,1·fs, ≈0,5·fs, 0,04·fs) z nco_ftw.hex,
//    próbki co drugi takt; sin i cos bit w bit z nco_sin.hex / nco_cos.hex (model Pythona);
//  - sd_dac: dla pięciu stałych wartości liczba jedynek w 65 536 taktach = x + 32 768 (±1).
`timescale 1ns / 1ps
`default_nettype none

module tb_nco;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [31:0] f_mem [0:4095];
    logic  [15:0] s_mem [0:4095];
    logic  [15:0] c_mem [0:4095];
    logic         we = 1'b0;
    logic  [31:0] ftw = 32'd0;
    logic signed [15:0] s, c;
    logic        v;
    nco u_nco (.clk(clk), .rst(rst), .we(we), .ftw(ftw), .sin_o(s), .cos_o(c), .wazne(v));

    logic  signed [15:0] dx = 16'sd0;
    logic               dq;
    sd_dac u_dac (.clk(clk), .rst(rst), .x(dx), .q(dq));

    int n = 0, bs = 0, bc = 0, i, k, jed, smax = 0;
    always @(posedge clk) if (!rst && v) begin
        if (s !== s_mem[n]) begin if (bs < 5) $display("sin: probka %0d: %0d, model %0d", n, s, $signed(s_mem[n])); bs = bs + 1; end
        if (c !== c_mem[n]) begin if (bc < 5) $display("cos: probka %0d: %0d, model %0d", n, c, $signed(c_mem[n])); bc = bc + 1; end
        if (s > smax) smax = s;
        n = n + 1;
    end

    logic signed [15:0] wart [0:4];
    initial begin
        $readmemh("nco_ftw.hex", f_mem);
        $readmemh("nco_sin.hex", s_mem);
        $readmemh("nco_cos.hex", c_mem);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (i = 0; i < 4096; i = i + 1) begin
            @(negedge clk) begin ftw = f_mem[i]; we = 1'b1; end
            @(negedge clk) we = 1'b0;
        end
        repeat (5) @(negedge clk);
        $display("nco: %0d probek, niezgodnych sin %0d, cos %0d, max sin %0d", n, bs, bc, smax);
        if (n != 4096 || bs != 0 || bc != 0) errors = errors + 1;

        wart[0] = -16'sd32768; wart[1] = -16'sd1000; wart[2] = 16'sd0; wart[3] = 16'sd12345; wart[4] = 16'sd32767;
        for (k = 0; k < 5; k = k + 1) begin
            @(negedge clk) dx = wart[k];
            repeat (100) @(negedge clk);
            jed = 0;
            for (i = 0; i < 65536; i = i + 1) begin
                @(negedge clk);
                if (dq) jed = jed + 1;
            end
            $display("sd_dac: x = %0d: jedynek %0d z 65536 (oczekiwane %0d)", wart[k], jed, wart[k] + 32768);
            if (jed - (wart[k] + 32768) > 1 || (wart[k] + 32768) - jed > 1) errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
