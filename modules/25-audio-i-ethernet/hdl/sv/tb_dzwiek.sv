// Testbench (SystemVerilog) 25.02: biquad (dolnoprzepustowy, fc = 1 kHz, Q = 0,707, fs = 48 828 Hz; współczynniki z wzorów RBJ
// policzone i skwantowane w testbenchu) i echo (D = 100, g = 128).
//  - biquad: 3000 losowych próbek porównanych bit w bit z modelem całkowitoliczbowym; odpowiedź na sinusy
//    200 Hz, 1 kHz i 5 kHz (amplituda w stanie ustalonym, dB);
//  - echo: odpowiedź impulsowa (1, 1/2, 1/4 co D próbek) i 3000 losowych próbek z nasyceniem bit w bit z modelem.
`timescale 1ns / 1ps
`default_nettype none

module tb_dzwiek;
    logic clk = 1'b0;
    always #40 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    // ---- biquad
    logic                we = 1'b0;
    logic  signed [23:0] x = 0;
    logic  signed [17:0] b0, b1, b2, a1, a2;
    logic signed [23:0] y;
    logic               y_w;
    biquad u_bq (.clk(clk), .rst(rst), .we(we), .x(x), .b0(b0), .b1(b1), .b2(b2), .a1(a1), .a2(a2), .y(y), .y_wazne(y_w));

    // ---- echo
    logic                ewe = 1'b0;
    logic  signed [23:0] ex = 0;
    logic signed [23:0] ey;
    logic               ey_w;
    echo #(.D(100)) u_echo (.clk(clk), .rst(rst), .we(ewe), .x(ex), .g(8'd128), .y(ey), .y_wazne(ey_w));

    // model biquad
    logic signed [63:0] mx1 = 0, mx2 = 0, my1 = 0, my2 = 0;
    function signed [63:0] model_bq(input signed [63:0] xx);
        logic signed [63:0] acc, w;
        begin
            acc = b0 * xx + b1 * mx1 + b2 * mx2 - a1 * my1 - a2 * my2;
            w   = (acc + 64'sd32768) >>> 16;
            if (w > 64'sd8388607) w = 64'sd8388607;
            if (w < -64'sd8388608) w = -64'sd8388608;
            model_bq = w;
        end
    endfunction

    task probka(input signed [23:0] v);
        begin
            @(negedge clk) begin x = v; we = 1'b1; end
            @(negedge clk) we = 1'b0;
            @(posedge y_w); #1;
        end
    endtask

    real    pi, w0, al, q0, kb0, kb1, kb2, ka0, ka1, ka2, fs, amp, g;
    int seed = 7, n, bl_bq = 0, maks, k, f;
    logic signed [63:0] m;

    // model echa
    logic signed [23:0] hist [0:99];
    int ep = 0, bl_ec = 0;
    function signed [23:0] model_ec(input signed [23:0] xx, input signed [23:0] stara);
        logic signed [63:0] s;
        begin
            s = xx + (($signed({{40{stara[23]}}, stara[23:8], 8'd0}) * 64'sd128) >>> 8);
            if (s > 64'sd8388607) s = 64'sd8388607;
            if (s < -64'sd8388608) s = -64'sd8388608;
            model_ec = s[23:0];
        end
    endfunction
    task eprobka(input signed [23:0] v);
        begin
            @(negedge clk) begin ex = v; ewe = 1'b1; end
            @(negedge clk) ewe = 1'b0;
            @(posedge ey_w); #1;
        end
    endtask

    initial begin
        pi = 3.14159265358979; fs = 12500000.0 / 256.0;
        w0 = 2.0 * pi * 1000.0 / fs; q0 = 0.7071;
        al = $sin(w0) / (2.0 * q0);
        kb0 = (1.0 - $cos(w0)) / 2.0; kb1 = 1.0 - $cos(w0); kb2 = kb0;
        ka0 = 1.0 + al; ka1 = -2.0 * $cos(w0); ka2 = 1.0 - al;
        b0 = $rtoi(kb0 / ka0 * 65536.0 + 0.5); b1 = $rtoi(kb1 / ka0 * 65536.0 + 0.5); b2 = b0;
        a1 = -$rtoi(-ka1 / ka0 * 65536.0 + 0.5); a2 = $rtoi(ka2 / ka0 * 65536.0 + 0.5);
        $display("wspolczynniki Q2.16: b0 = %0d, b1 = %0d, b2 = %0d, a1 = %0d, a2 = %0d", b0, b1, b2, a1, a2);
        for (n = 0; n < 100; n = n + 1) hist[n] = 0;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        // 1. losowe próbki, bit w bit
        for (n = 0; n < 3000; n = n + 1) begin
            k = $random(seed);
            m = model_bq(k >>> 8);
            probka(k >>> 8);
            if (y !== m[23:0]) begin
                if (bl_bq < 5) $display("biquad: probka %0d: %0d, model %0d", n, y, m);
                bl_bq = bl_bq + 1;
            end
            mx2 = mx1; mx1 = k >>> 8; my2 = my1; my1 = m;
        end
        $display("biquad: 3000 losowych probek, niezgodnych z modelem %0d", bl_bq);
        if (bl_bq != 0) errors = errors + 1;
        // 2. odpowiedź na sinusy
        for (f = 0; f < 3; f = f + 1) begin
            maks = 0;
            for (n = 0; n < 2400; n = n + 1) begin
                amp = 4194304.0 * $sin(2.0 * pi * ((f == 0) ? 200.0 : (f == 1) ? 1000.0 : 5000.0) * n / fs);
                k = $rtoi(amp);
                m = model_bq(k);
                probka(k);
                mx2 = mx1; mx1 = k; my2 = my1; my1 = m;
                if (n >= 1200 && (y > maks)) maks = y;
            end
            g = 20.0 * $log10(maks / 4194304.0);
            $display("sinus %0d Hz: amplituda wyjscia %0d, wzmocnienie %.2f dB", (f == 0) ? 200 : (f == 1) ? 1000 : 5000, maks, g);
            if (f == 0 && (g > 0.5 || g < -0.5)) errors = errors + 1;
            if (f == 1 && (g > -2.0 || g < -4.0)) errors = errors + 1;
            if (f == 2 && g > -20.0) errors = errors + 1;
        end
        // 3. echo: impuls
        eprobka(24'sd4194304);
        if (ey !== 24'sd4194304) errors = errors + 1;
        hist[0] = ey; ep = 1;
        for (n = 1; n < 301; n = n + 1) begin
            eprobka(0);
            if ((n == 100 && ey !== 24'sd2097152) || (n == 200 && ey !== 24'sd1048576) || (n == 300 && ey !== 24'sd524288) ||
                (n % 100 != 0 && ey !== 0)) bl_ec = bl_ec + 1;
            hist[ep % 100] = ey; ep = ep + 1;
        end
        $display("echo: odpowiedz impulsowa (1, 1/2, 1/4, 1/8 co 100 probek), bledow %0d", bl_ec);
        // 4. echo: losowe z nasyceniem
        for (n = 0; n < 3000; n = n + 1) begin
            k = $random(seed);
            eprobka(k >>> 8);
            if (ey !== model_ec(k >>> 8, hist[ep % 100])) bl_ec = bl_ec + 1;
            hist[ep % 100] = ey; ep = ep + 1;
        end
        $display("echo: razem bledow %0d (z 3000 losowymi probkami)", bl_ec);
        if (bl_ec != 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
