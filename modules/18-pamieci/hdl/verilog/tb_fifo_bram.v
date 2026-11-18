// Testbench fifo_bram: wersje standardowa (FWFT = 0) i z wyprzedzeniem (FWFT = 1) na tym samym
// pobudzeniu w trzech fazach (przewaga zapisów, przewaga odczytów, po równo). Model: kolejka w tablicy.
// Sprawdzane: kolejność i wartości danych, licznik count, flagi full/empty/almost_*, odrzucanie zapisu
// przy full i odczytu przy empty; pokrycie: każda flaga osiągnięta.
`timescale 1ns / 1ps
`default_nettype none

module tb_fifo_bram;
    localparam W = 8, AW = 4, DEPTH = 1 << AW, AF = 12, AE = 2, N = 6000;
    reg clk = 1'b0, rst = 1'b1;
    always #5 clk = ~clk;
    reg          wr_en = 1'b0, rd_en = 1'b0;
    reg  [W-1:0] din = 0;
    wire [W-1:0] dout0, dout1;
    wire         full0, full1, af0, af1, empty0, empty1, ae0, ae1;
    wire [AW+1:0] cnt0, cnt1;
    fifo_bram #(.W(W), .AW(AW), .FWFT(0), .AF(AF), .AE(AE)) u0 (.clk(clk), .rst(rst), .wr_en(wr_en), .din(din),
        .full(full0), .almost_full(af0), .rd_en(rd_en), .dout(dout0), .empty(empty0), .almost_empty(ae0), .count(cnt0));
    fifo_bram #(.W(W), .AW(AW), .FWFT(1), .AF(AF), .AE(AE)) u1 (.clk(clk), .rst(rst), .wr_en(wr_en), .din(din),
        .full(full1), .almost_full(af1), .rd_en(rd_en), .dout(dout1), .empty(empty1), .almost_empty(ae1), .count(cnt1));

    // modele: tablice kołowe
    reg [W-1:0] q0 [0:63];
    reg [W-1:0] q1 [0:63];
    integer h0 = 0, t0 = 0, h1 = 0, t1 = 0;            // głowa (odczyt), ogon (zapis)
    integer n, errors = 0, pw = 50, pr = 50;
    integer c_full0 = 0, c_full1 = 0, c_empty = 0, c_af = 0, c_ae = 0, odrzucone = 0;
    reg [W-1:0] oczek0;
    reg         czekam0 = 1'b0;

    task blad(input [8*32-1:0] co);
        begin
            $display("%0t: %0s", $time, co);
            errors = errors + 1;
        end
    endtask

    initial begin
        #23 rst = 1'b0;
        for (n = 0; n < N; n = n + 1) begin
            @(negedge clk);
            // sprawdzenia przed zboczem
            if (czekam0 && dout0 !== oczek0) blad("std: zla dana");
            czekam0 = 1'b0;
            if (cnt0 != t0 - h0) blad("std: count");
            if (empty0 !== (t0 == h0)) blad("std: empty");
            if (full0 !== (t0 - h0 == DEPTH)) blad("std: full");
            if (cnt1 != t1 - h1) blad("fwft: count");
            if (!empty1 && dout1 !== q1[h1 % 64]) blad("fwft: zla dana na wyjsciu");
            if (full1 && (t1 - h1 < DEPTH)) blad("fwft: full za wczesnie");
            if (af0 !== (cnt0 >= AF) || ae0 !== (cnt0 <= AE)) blad("std: almost");
            if (af1 !== (cnt1 >= AF) || ae1 !== (cnt1 <= AE)) blad("fwft: almost");
            if (t0 - h0 > DEPTH || t1 - h1 > DEPTH + 1) blad("przepelnienie modelu");
            c_full0 = c_full0 + full0; c_full1 = c_full1 + full1; c_empty = c_empty + (empty0 & empty1);
            c_af = c_af + af0; c_ae = c_ae + ae0;
            // fazy: przewaga zapisów, odczytów, po równo
            pw = (n % 1500 < 500) ? 80 : (n % 1500 < 1000) ? 20 : 50;
            pr = 100 - pw;
            wr_en = ($urandom % 100) < pw;
            rd_en = ($urandom % 100) < pr;
            din   = $random;
            // model (stan sprzed zbocza)
            if (wr_en && !full0) begin q0[t0 % 64] = din; t0 = t0 + 1; end
            if (wr_en && full0) odrzucone = odrzucone + 1;
            if (rd_en && !empty0) begin oczek0 = q0[h0 % 64]; h0 = h0 + 1; czekam0 = 1'b1; end
            if (wr_en && !full1) begin q1[t1 % 64] = din; t1 = t1 + 1; end
            if (rd_en && !empty1) h1 = h1 + 1;
        end
        $display("slow: std %0d, fwft %0d; takty full %0d/%0d, empty %0d, almost_full %0d, almost_empty %0d, odrzucone %0d",
                 t0, t1, c_full0, c_full1, c_empty, c_af, c_ae, odrzucone);
        if (errors == 0 && c_full0 > 0 && c_full1 > 0 && c_empty > 0 && c_af > 0 && c_ae > 0 && odrzucone > 0)
            $display("PASS");
        else
            $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
