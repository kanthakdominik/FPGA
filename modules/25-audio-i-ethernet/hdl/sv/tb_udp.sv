// Testbench (SystemVerilog) 25.04: udp_nad i arp_odp.
//  1. udp_nad: datagram z 18 bajtami danych (odbiorca losowo wstrzymuje); bajty porównane z ramką zbudowaną
//     w testbenchu pole po polu, suma kontrolna IPv4 sprawdzona niezależnie (suma słów nagłówka = 0xFFFF).
//  2. udp_nad -> mii_tx -> mii_rx: datagram 1000 B przechodzi z poprawnym CRC i niezmienionymi bajtami.
//  3. arp_odp (odbiór 25 MHz, nadawanie ok. 24,9 MHz — zegary niezależne): zapytanie o nasz adres -> odpowiedź
//     42 B zgodna z oczekiwaną i nauczony adres pytającego; zapytanie o inny adres i zapytanie ze złym CRC —
//     brak odpowiedzi.
`timescale 1ns / 1ps
`default_nettype none

module tb_udp;
    logic clk = 1'b0, clk_t = 1'b0;
    always #20 clk = ~clk;                        // 25 MHz (nadawanie UDP, odbiór)
    always #20.1 clk_t = ~clk_t;                  // ok. 24,9 MHz (nadawanie ARP)
    logic rst = 1'b1;
    int errors = 0;

    localparam [47:0] MAC_FPGA = 48'h02_00_00_00_00_01, MAC_PC = 48'h00_1B_21_3C_4D_5E;
    localparam [31:0] IP_FPGA  = {8'd192, 8'd168, 8'd1, 8'd200}, IP_PC = {8'd192, 8'd168, 8'd1, 8'd100};

    // ---- udp_nad
    logic         start = 1'b0;
    logic  [10:0] dl = 11'd18;
    logic        zajety, p_gotowy, m_wazne, m_ostatni;
    logic [7:0]  m_dane;
    logic  [7:0]  p_dane = 8'd0;
    logic         m_gotowy = 1'b1, przez_mii = 1'b0;
    logic        tx_gotowy;
    udp_nad u_udp (.clk(clk), .rst(rst), .start(start), .dlugosc(dl), .mac_zr(MAC_FPGA), .mac_cel(MAC_PC),
                   .ip_zr(IP_FPGA), .ip_cel(IP_PC), .port_zr(16'd5005), .port_cel(16'd5006), .zajety(zajety),
                   .p_dane(p_dane), .p_wazne(1'b1), .p_gotowy(p_gotowy),
                   .m_dane(m_dane), .m_wazne(m_wazne), .m_ostatni(m_ostatni),
                   .m_gotowy(przez_mii ? tx_gotowy : m_gotowy));
    always @(posedge clk) if (p_gotowy) p_dane <= p_dane + 8'd1;      // dane: 0, 1, 2, …

    // ---- mii_tx -> mii_rx
    logic [3:0] txd;
    logic       tx_en, przerwa;
    logic [7:0] r_dane;
    logic       r_wazne, r_koniec, r_crc_ok, r_blad;
    logic [10:0] r_dl;
    mii_tx u_tx (.clk(clk), .rst(rst), .s_dane(m_dane), .s_wazne(m_wazne && przez_mii), .s_ostatni(m_ostatni),
                 .s_gotowy(tx_gotowy), .txd(txd), .tx_en(tx_en), .przerwa(przerwa));
    mii_rx u_rx (.clk(clk), .rst(rst), .rxd(txd), .rx_dv(tx_en), .rx_er(1'b0), .m_dane(r_dane), .m_wazne(r_wazne),
                 .koniec(r_koniec), .crc_ok(r_crc_ok), .dlugosc(r_dl), .blad(r_blad));

    // ---- arp_odp: wejście bajtowe sterowane z testbenchu (jak z mii_rx)
    logic  [7:0] a_dane = 0;
    logic        a_wazne = 1'b0, a_koniec = 1'b0, a_crc = 1'b0;
    logic       chce, o_wazne, o_ostatni;
    logic [7:0] o_dane;
    logic [47:0] mac_pyt;
    logic [31:0] ip_pyt;
    logic        nauczony;
    logic         o_gotowy = 1'b1;
    arp_odp u_arp (.clk_rx(clk), .rst_rx(rst), .r_dane(a_dane), .r_wazne(a_wazne), .r_koniec(a_koniec),
                   .r_crc_ok(a_crc), .mac_moj(MAC_FPGA), .ip_moj(IP_FPGA),
                   .clk_tx(clk_t), .rst_tx(rst), .chce(chce), .m_dane(o_dane), .m_wazne(o_wazne),
                   .m_ostatni(o_ostatni), .m_gotowy(o_gotowy),
                   .mac_pyt(mac_pyt), .ip_pyt(ip_pyt), .nauczony(nauczony));

    logic [7:0] ocz [0:2047];
    logic [7:0] zebr [0:2047];
    int   nz = 0, i, j, seed = 11, s, bl;
    function [7:0] bajt48(input [47:0] v, input int k); bajt48 = v[8 * (5 - k) +: 8]; endfunction
    function [7:0] bajt32(input [31:0] v, input int k); bajt32 = v[8 * (3 - k) +: 8]; endfunction

    // zbieranie strumienia udp_nad (bez mii)
    always @(posedge clk) if (!przez_mii && m_wazne && m_gotowy) begin zebr[nz] = m_dane; nz = nz + 1; end
    always @(negedge clk) m_gotowy = (($random(seed) & 32'h7fffffff) % 4) != 0;

    // zebranie odpowiedzi ARP
    logic [7:0] arp [0:63];
    int   na = 0;
    always @(posedge clk_t) if (o_wazne && o_gotowy) begin arp[na] = o_dane; na = na + 1; end

    // odbiór z mii_rx
    logic [7:0] rx [0:2047];
    int   nr = 0;
    always @(posedge clk) if (r_wazne) begin rx[nr] = r_dane; nr = nr + 1; end

    task zapytanie(input [31:0] szukany, input crc_dobry);
        logic [7:0] ramka [0:59];
        int q;
        begin
            for (q = 0; q < 60; q = q + 1) ramka[q] = 8'h00;
            for (q = 0; q < 6; q = q + 1) begin ramka[q] = 8'hFF; ramka[6 + q] = bajt48(MAC_PC, q); end
            ramka[12] = 8'h08; ramka[13] = 8'h06; ramka[14] = 8'h00; ramka[15] = 8'h01; ramka[16] = 8'h08;
            ramka[17] = 8'h00; ramka[18] = 8'h06; ramka[19] = 8'h04; ramka[20] = 8'h00; ramka[21] = 8'h01;
            for (q = 0; q < 6; q = q + 1) ramka[22 + q] = bajt48(MAC_PC, q);
            for (q = 0; q < 4; q = q + 1) ramka[28 + q] = bajt32(IP_PC, q);
            for (q = 0; q < 4; q = q + 1) ramka[38 + q] = bajt32(szukany, q);
            for (q = 0; q < 60; q = q + 1) begin
                @(negedge clk) begin a_dane = ramka[q]; a_wazne = 1'b1; end
                @(negedge clk) a_wazne = 1'b0;                     // bajt co dwa takty, jak z MII
            end
            @(negedge clk) begin a_koniec = 1'b1; a_crc = crc_dobry; end
            @(negedge clk) a_koniec = 1'b0;
            repeat (200) @(negedge clk);
        end
    endtask

    initial begin
        repeat (5) @(negedge clk);
        rst = 1'b0;
        // ---- 1. datagram 18 B
        @(negedge clk) start = 1'b1;
        @(negedge clk) start = 1'b0;
        wait (!zajety);
        repeat (2) @(negedge clk);
        for (i = 0; i < 6; i = i + 1) begin ocz[i] = bajt48(MAC_PC, i); ocz[6 + i] = bajt48(MAC_FPGA, i); end
        ocz[12] = 8'h08; ocz[13] = 8'h00; ocz[14] = 8'h45; ocz[15] = 8'h00; ocz[16] = 8'h00; ocz[17] = 8'd46;
        ocz[18] = 8'h00; ocz[19] = 8'h01; ocz[20] = 8'h40; ocz[21] = 8'h00; ocz[22] = 8'h40; ocz[23] = 8'h11;
        ocz[24] = 8'h00; ocz[25] = 8'h00;
        for (i = 0; i < 4; i = i + 1) begin ocz[26 + i] = bajt32(IP_FPGA, i); ocz[30 + i] = bajt32(IP_PC, i); end
        ocz[34] = 8'h13; ocz[35] = 8'h8D; ocz[36] = 8'h13; ocz[37] = 8'h8E; ocz[38] = 8'h00; ocz[39] = 8'd26;
        ocz[40] = 8'h00; ocz[41] = 8'h00;
        for (i = 0; i < 18; i = i + 1) ocz[42 + i] = i;
        s = 0;                                                     // suma IPv4 policzona niezależnie
        for (i = 14; i < 34; i = i + 2) s = s + {ocz[i], ocz[i + 1]};
        s = (s & 16'hFFFF) + (s >> 16); s = (s & 16'hFFFF) + (s >> 16);
        ocz[24] = ~s[15:8]; ocz[25] = ~s[7:0];
        bl = 0;
        if (nz != 60) bl = bl + 1;
        for (i = 0; i < 60; i = i + 1) if (zebr[i] !== ocz[i]) begin
            if (bl < 5) $display("bajt %0d: %h, oczekiwano %h", i, zebr[i], ocz[i]);
            bl = bl + 1;
        end
        s = 0;
        for (i = 14; i < 34; i = i + 2) s = s + {zebr[i], zebr[i + 1]};
        s = (s & 16'hFFFF) + (s >> 16); s = (s & 16'hFFFF) + (s >> 16);
        $display("datagram 18 B: %0d bajtow ramki, niezgodnych %0d; suma kontrolna IP %h%h, suma naglowka %h",
                 nz, bl, zebr[24], zebr[25], s[15:0]);
        if (bl != 0 || s[15:0] != 16'hFFFF) errors = errors + 1;

        // ---- 2. datagram 1000 B przez MII
        przez_mii = 1'b1; dl = 11'd1000;
        @(negedge clk) begin start = 1'b1; p_dane = 8'd0; end
        @(negedge clk) start = 1'b0;
        @(posedge r_koniec); #1;
        bl = 0;
        for (i = 0; i < 1000; i = i + 1) if (rx[42 + i] !== i[7:0]) bl = bl + 1;
        $display("datagram 1000 B przez mii_tx/mii_rx: ramka %0d B, crc_ok = %b, bledow danych %0d, id IP %h%h",
                 r_dl, r_crc_ok, bl, rx[18], rx[19]);
        if (bl != 0 || !r_crc_ok || r_dl != 11'd1042 || rx[19] != 8'h02) errors = errors + 1;

        // ---- 3. ARP
        zapytanie(IP_FPGA, 1'b1);
        bl = 0;
        for (i = 0; i < 6; i = i + 1) begin
            if (arp[i] !== bajt48(MAC_PC, i) || arp[6 + i] !== bajt48(MAC_FPGA, i) || arp[22 + i] !== bajt48(MAC_FPGA, i) ||
                arp[32 + i] !== bajt48(MAC_PC, i)) bl = bl + 1;
        end
        for (i = 0; i < 4; i = i + 1)
            if (arp[28 + i] !== bajt32(IP_FPGA, i) || arp[38 + i] !== bajt32(IP_PC, i)) bl = bl + 1;
        if (arp[12] !== 8'h08 || arp[13] !== 8'h06 || arp[20] !== 8'h00 || arp[21] !== 8'h02) bl = bl + 1;
        $display("ARP: zapytanie o %0d.%0d.%0d.%0d -> odpowiedz %0d B, bledow %0d; nauczony %b: MAC %h, IP %h",
                 IP_FPGA[31:24], IP_FPGA[23:16], IP_FPGA[15:8], IP_FPGA[7:0], na, bl, nauczony, mac_pyt, ip_pyt);
        if (na != 42 || bl != 0 || !nauczony || mac_pyt != MAC_PC || ip_pyt != IP_PC) errors = errors + 1;
        zapytanie({8'd192, 8'd168, 8'd1, 8'd201}, 1'b1);
        zapytanie(IP_FPGA, 1'b0);
        $display("ARP: zapytanie o inny adres i zapytanie ze zlym CRC -> odpowiedzi razem %0d B (oczekiwane 42)", na);
        if (na != 42) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
