// Testbench 26.05: fft64. Trzy ramki po 64 próbki zespolone z fft_we.hex (impuls, ton zespolony w prążku 5,
// szum), wyniki w kolejności naturalnej bit w bit z fft_wy.hex (model Pythona). Pomiar: takty od ostatniej
// próbki do pierwszego wyniku i prążek o największym module w ramce z tonem.
`timescale 1ns / 1ps
`default_nettype none

module tb_fft;
    reg clk = 1'b0;
    always #5 clk = ~clk;
    reg rst = 1'b1;
    integer errors = 0;

    reg  [31:0] x_mem [0:191];
    reg  [31:0] y_mem [0:191];
    reg                we = 1'b0;
    reg  signed [15:0] xr = 16'sd0, xi = 16'sd0;
    wire               gotowy, v;
    wire signed [15:0] yr, yi;
    fft64 u_fft (.clk(clk), .rst(rst), .we(we), .xr(xr), .xi(xi), .gotowy(gotowy), .yr(yr), .yi(yi), .wy_wazne(v));

    integer n = 0, bl = 0, i, f, takt = 0, t_kon = 0, lat = -1, maks = 0, prazek = -1, m;
    always @(posedge clk) takt <= takt + 1;
    always @(posedge clk) if (!rst && v) begin
        if ({yr, yi} !== y_mem[n]) begin
            if (bl < 5) $display("wynik %0d: (%0d, %0d), model (%0d, %0d)", n, yr, yi, $signed(y_mem[n][31:16]), $signed(y_mem[n][15:0]));
            bl = bl + 1;
        end
        if (n == 0) lat = takt - t_kon;
        if (n >= 64 && n < 128) begin
            m = yr * yr + yi * yi;
            if (m > maks) begin maks = m; prazek = n - 64; end
        end
        n = n + 1;
    end

    initial begin
        $readmemh("fft_we.hex", x_mem);
        $readmemh("fft_wy.hex", y_mem);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (f = 0; f < 3; f = f + 1) begin
            while (!gotowy) @(negedge clk);
            for (i = 0; i < 64; i = i + 1) begin
                @(negedge clk) begin xr = x_mem[64*f + i][31:16]; xi = x_mem[64*f + i][15:0]; we = 1'b1; end
            end
            @(negedge clk) we = 1'b0;
            if (f == 0) t_kon = takt;
            @(negedge clk);
        end
        while (n < 192) @(negedge clk);
        repeat (5) @(negedge clk);
        $display("fft64: 3 ramki, %0d wynikow, niezgodnych z modelem %0d", n, bl);
        $display("od ostatniej probki do pierwszego wyniku: %0d taktow; ton: najwiekszy prazek %0d", lat, prazek);
        if (n != 192 || bl != 0 || prazek != 5) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
