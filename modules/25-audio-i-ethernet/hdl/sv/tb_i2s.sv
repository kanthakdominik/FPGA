// Testbench (SystemVerilog) 25.01: i2s_master z modelem kodeka (slave I2S). Model odbiera dout według formatu I2S (bit MSB jeden
// takt BCLK po zmianie WCLK, próbkowanie na narastającym BCLK) i nadaje własne próbki na din (zmiana po opadającym
// BCLK). 200 ramek losowych próbek w obie strony; porównanie ciągów próbek (z wyrównaniem opóźnienia potoku),
// pomiar BCLK, WCLK i liczby taktów BCLK na ramkę.
`timescale 1ns / 1ps
`default_nettype none

module tb_i2s;
    logic clk = 1'b0;
    always #40 clk = ~clk;                        // 12,5 MHz
    logic rst = 1'b1;
    int errors = 0;

    logic  [23:0] tx_l = 0, tx_p = 0;
    logic [23:0] rx_l, rx_p;
    logic        ramka, bclk, wclk, dout;
    logic         din = 1'b0;
    i2s_master dut (.clk(clk), .rst(rst), .tx_l(tx_l), .tx_p(tx_p), .rx_l(rx_l), .rx_p(rx_p), .ramka(ramka),
                    .bclk(bclk), .wclk(wclk), .dout(dout), .din(din));

    localparam int M = 200;
    logic [23:0] wys_l [0:M+9], wys_p [0:M+9];     // wysłane przez FPGA
    logic [23:0] mod_l [0:M+9], mod_p [0:M+9];     // wysłane przez model
    logic [23:0] odb_l [0:M+9], odb_p [0:M+9];     // odebrane przez model
    logic [23:0] fpg_l [0:M+9], fpg_p [0:M+9];     // odebrane przez FPGA
    int nw = 0, nm = 0, no = 0, nf = 0, seed = 25, i, j;

    // ---- FPGA: nowe próbki po każdym impulsie ramka, zapis odebranych
    always @(posedge clk) if (ramka) begin
        if (nf < M + 10) begin fpg_l[nf] = rx_l; fpg_p[nf] = rx_p; end
        nf = nf + 1;
        tx_l <= $random(seed); tx_p <= $random(seed);
    end
    always @(posedge clk) if (ramka && nw < M + 10) begin #1; wys_l[nw] = tx_l; wys_p[nw] = tx_p; nw = nw + 1; end

    // ---- model kodeka: odbiór
    logic        w_pop = 1'b0;
    int    cnt = 99;
    logic [23:0] sr = 0;
    always @(posedge bclk) begin
        if (wclk != w_pop) cnt = 0; else cnt = cnt + 1;
        if (cnt >= 1 && cnt <= 24) sr = {sr[22:0], dout};
        if (cnt == 24 && no < M + 10) begin
            if (!wclk) odb_l[no] = sr;
            else begin odb_p[no] = sr; no = no + 1; end
        end
        w_pop = wclk;
    end
    // ---- model kodeka: nadawanie (zmiana po opadającym BCLK)
    logic        wn_pop = 1'b1;
    int    poz = 99;
    logic [23:0] sl = 0, sp = 0;
    always @(negedge bclk) begin
        if (wclk != wn_pop) poz = 0; else poz = poz + 1;
        if (poz == 0 && !wclk) begin                         // początek kanału lewego: nowa para próbek
            sl = $random(seed); sp = $random(seed);
            if (nm < M + 10) begin mod_l[nm] = sl; mod_p[nm] = sp; nm = nm + 1; end
        end
        din <= #10 (poz >= 1 && poz <= 24) ? (wclk ? sp[24 - poz] : sl[24 - poz]) : 1'b0;
        wn_pop = wclk;
    end

    // ---- pomiar zegarów
    realtime tb0 = 0, tw0 = 0, okr_b = 0, okr_w = 0;
    int  nb = 0, nb_w = 0, nb_min = 999, nb_max = 0;
    always @(posedge bclk) begin
        if (tb0 > 0) okr_b = $realtime - tb0;
        tb0 = $realtime; nb = nb + 1;
    end
    always @(posedge wclk) begin
        if (tw0 > 0) begin
            okr_w = $realtime - tw0;
            if (nb - nb_w < nb_min) nb_min = nb - nb_w;
            if (nb - nb_w > nb_max) nb_max = nb - nb_w;
        end
        tw0 = $realtime; nb_w = nb;
    end

    // porównanie ciągów z przesunięciem -3..4 (opóźnienie potoku nieznane z góry)
    int opozn;
    function int porownaj(input int ktory);
        int o, k, zle, najl;
        begin
            najl = 999;
            for (o = 0; o < 8; o = o + 1) begin
                zle = 0;
                for (k = 8; k < M - 5; k = k + 1)
                    if (ktory == 0 ? (odb_l[k] !== wys_l[k - o + 3] || odb_p[k] !== wys_p[k - o + 3])
                                   : (fpg_l[k] !== mod_l[k - o + 3] || fpg_p[k] !== mod_p[k - o + 3])) zle = zle + 1;
                if (zle < najl) begin najl = zle; opozn = o - 3; end
            end
            porownaj = najl;
        end
    endfunction

    int z1, z2;
    initial begin
        for (i = 0; i < M + 10; i = i + 1) begin
            wys_l[i] = 0; wys_p[i] = 0; mod_l[i] = 0; mod_p[i] = 0; odb_l[i] = 0; odb_p[i] = 0; fpg_l[i] = 0; fpg_p[i] = 0;
        end
        repeat (3) @(posedge clk);
        rst = 1'b0;
        wait (nf >= M + 2 && no >= M + 2);
        z1 = porownaj(0);
        $display("FPGA -> kodek: probki odebrane przez model z opoznieniem %0d ramek wzgledem podania na tx_l/tx_p", opozn);
        z2 = porownaj(1);
        $display("kodek -> FPGA: probki modelu na rx_l/rx_p z opoznieniem %0d ramek", opozn);
        $display("BCLK %.4f MHz, WCLK (fs) %.3f kHz, taktow BCLK na ramke %0d..%0d", 1.0e3 / okr_b, 1.0e6 / okr_w, nb_min, nb_max);
        $display("ramek %0d: FPGA -> kodek bledow %0d, kodek -> FPGA bledow %0d", M, z1, z2);
        if (z1 != 0 || z2 != 0 || nb_min != 64 || nb_max != 64) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
