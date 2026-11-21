// Testbench 25.03: mii_tx -> mii_rx w pętli (zegar 25 MHz). Ramki o długościach 1, 14, 59, 60, 61, 100, 1514
// i 20 losowych; sprawdza: preambułę i SFD na linii, FCS na linii równe CRC-32 policzonemu w testbenchu
// (algorytm sprawdzony wektorem "123456789" -> 0xCBF43926), bajty odebrane = wysłane + uzupełnienie zerami do
// 60 B, crc_ok i długość, przerwę międzyramkową ≥ 24 takty; ramka z przekłamanym bitem -> crc_ok = 0.
`timescale 1ns / 1ps
`default_nettype none

module tb_mii;
    reg clk = 1'b0;
    always #20 clk = ~clk;                        // 25 MHz
    reg rst = 1'b1;
    integer errors = 0;

    reg  [7:0] s_dane = 0;
    reg        s_wazne = 1'b0, s_ostatni = 1'b0;
    wire       s_gotowy, tx_en, przerwa;
    wire [3:0] txd;
    reg        psuj = 1'b0;                       // przekłamanie bitu na linii
    reg        zep = 1'b0;
    wire [3:0] rxd = txd ^ {3'b000, psuj};
    wire [7:0] m_dane;
    wire       m_wazne, koniec, crc_ok, blad;
    wire [10:0] dlugosc;
    mii_tx u_tx (.clk(clk), .rst(rst), .s_dane(s_dane), .s_wazne(s_wazne), .s_ostatni(s_ostatni), .s_gotowy(s_gotowy),
                 .txd(txd), .tx_en(tx_en), .przerwa(przerwa));
    mii_rx u_rx (.clk(clk), .rst(rst), .rxd(rxd), .rx_dv(tx_en), .rx_er(1'b0), .m_dane(m_dane), .m_wazne(m_wazne),
                 .koniec(koniec), .crc_ok(crc_ok), .dlugosc(dlugosc), .blad(blad));

    function [31:0] crc32(input [31:0] c, input [7:0] d);      // bit po bicie, najmłodszy pierwszy
        integer i;
        reg [31:0] r;
        reg        bit_;
        begin
            r = c;
            for (i = 0; i < 8; i = i + 1) begin
                bit_ = r[0] ^ d[i];
                r = {1'b0, r[31:1]};
                if (bit_) r = r ^ 32'hEDB88320;
            end
            crc32 = r;
        end
    endfunction

    reg [7:0] dane [0:2047];
    reg [7:0] linia [0:2100];                     // bajty złożone z linii (z preambułą)
    reg [7:0] odeb [0:2047];
    integer   nl = 0, no = 0, nlin, i, k, seed = 3, bl = 0, n_ramek = 0;
    reg       h = 1'b0;
    reg [3:0] mlod = 0;
    integer   cisza = 0, min_cisza = 999;
    reg       en_d = 1'b0;

    // linia: składanie bajtów, pomiar przerwy
    always @(posedge clk) begin
        if (tx_en) begin
            if (!h) begin mlod = txd; h = 1'b1; end
            else begin linia[nl] = {txd, mlod}; nl = nl + 1; h = 1'b0; end
        end
        if (!tx_en && en_d) cisza = 0;
        if (!tx_en) cisza = cisza + 1;
        if (tx_en && !en_d && n_ramek > 0 && cisza < min_cisza) min_cisza = cisza;
        en_d = tx_en;
    end
    always @(posedge clk) if (m_wazne) begin odeb[no] = m_dane; no = no + 1; end

    task ramka(input integer len, input integer zepsuj);
        integer j, oczl;
        reg [31:0] c;
        begin
            nl = 0; no = 0; h = 1'b0;
            for (j = 0; j < len; j = j + 1) dane[j] = $random(seed);
            @(negedge clk);
            zep = zepsuj;
            s_wazne = 1'b1;
            j = 0;
            s_dane = dane[0]; s_ostatni = (len == 1);
            while (j < len) begin
                @(posedge clk);
                if (s_gotowy) begin
                    j = j + 1;
                    #1;
                    s_dane = dane[j]; s_ostatni = (j == len - 1);
                    if (j == len) s_wazne = 1'b0;
                end
            end
            @(posedge koniec); #1;
            oczl = (len < 60) ? 60 : len;
            // preambuła, SFD
            for (j = 0; j < 7; j = j + 1) if (linia[j] !== 8'h55) bl = bl + 1;
            if (linia[7] !== 8'hD5) bl = bl + 1;
            // FCS na linii
            c = 32'hFFFFFFFF;
            for (j = 0; j < oczl; j = j + 1) c = crc32(c, (j < len) ? dane[j] : 8'h00);
            c = ~c;
            if (!zepsuj && {linia[8 + oczl + 3], linia[8 + oczl + 2], linia[8 + oczl + 1], linia[8 + oczl]} !== c) bl = bl + 1;
            if (nl != 8 + oczl + 4) bl = bl + 1;
            // odbiór
            if (zepsuj) begin
                if (crc_ok) bl = bl + 1;
            end else begin
                if (!crc_ok || blad || dlugosc != oczl || no != oczl) bl = bl + 1;
                for (j = 0; j < oczl; j = j + 1) if (odeb[j] !== ((j < len) ? dane[j] : 8'h00)) bl = bl + 1;
            end
            n_ramek = n_ramek + 1;
        end
    endtask

    always @(posedge zep) begin                   // przekłamanie jednego bitu w środku danych
        repeat (120) @(negedge clk);
        psuj = 1'b1;
        @(negedge clk);
        psuj = 1'b0;
        zep  = 1'b0;
    end
    reg [31:0] wektor;
    initial begin
        wektor = 32'hFFFFFFFF;
        for (i = 0; i < 9; i = i + 1) wektor = crc32(wektor, "1" + i);
        wektor = ~wektor;
        $display("CRC-32 testbenchu dla \"123456789\": %h", wektor);
        if (wektor !== 32'hCBF43926) errors = errors + 1;
        repeat (3) @(negedge clk);
        rst = 1'b0;
        ramka(1, 0); ramka(14, 0); ramka(59, 0); ramka(60, 0); ramka(61, 0); ramka(100, 0); ramka(1514, 0);
        for (k = 0; k < 20; k = k + 1) ramka(1 + (($random(seed) & 32'h7fffffff) % 1514), 0);
        $display("ramek poprawnych %0d: bledow %0d, minimalna przerwa miedzyramkowa %0d taktow", n_ramek, bl, min_cisza);
        if (bl != 0 || min_cisza < 24) errors = errors + 1;
        bl = 0;
        ramka(200, 1);
        $display("ramka z przeklamanym bitem: crc_ok = %b (oczekiwane 0), bledow %0d", crc_ok, bl);
        if (bl != 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
