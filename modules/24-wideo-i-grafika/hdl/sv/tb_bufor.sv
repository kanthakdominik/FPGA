// Testbench (SystemVerilog) 24.04: takt_wideo + bufor_ramki z modelem pamięci Avalon-MM (bursty, opóźnienie ≥ 3 takty, losowy
// waitrequest 30% i przerwy w readdatavalid 20%). Obraz 48×6 pikseli (6 słów na linię, bursty 4 + 2), SK = 1
// -> 96×12 na wyjściu; zegar piksela 25 MHz, pamięci ok. 71 MHz (zegary niezależne).
// Ramki w pamięci: A (BAZA0) i B (BAZA1) o różnych wzorach. Każda wyświetlona ramka jest klasyfikowana:
// czarna, A, B albo mieszana (błąd). przelacz zgłaszany w połowie ramek 2 i 4 -> oczekiwany ciąg: czarna, A,
// A, B, B, A, A. Mierzy też czas ładowania linii i sprawdza brak niedoborów (brak = 0).
`timescale 1ns / 1ps
`default_nettype none

module tb_bufor;
    logic clk_p = 1'b0, clk_m = 1'b0;
    always #20 clk_p = ~clk_p;                    // 25 MHz
    always #7  clk_m = ~clk_m;                    // ~71,4 MHz
    logic rst_p = 1'b1, rst_m = 1'b1;
    int errors = 0;

    localparam int SZER = 48, WYS = 6, SLOW = 6, RAMKA = SLOW * WYS;

    logic        hs, vs, de, nowa_ramka;
    logic [11:0] x, y;
    takt_wideo #(.H_AKT(96), .H_FP(4), .H_SYNC(6), .H_BP(6), .V_AKT(12), .V_FP(1), .V_SYNC(2), .V_BP(2),
                 .H_POL(1'b1), .V_POL(1'b1))
        u_takt (.clk(clk_p), .rst(rst_p), .hs(hs), .vs(vs), .de(de), .x(x), .y(y), .nowa_ramka(nowa_ramka));

    logic         przelacz = 1'b0;
    logic        aktywny, oczekuje, brak;
    logic [15:0] m_adr;
    logic        m_read;
    logic [4:0]  m_burstcount;
    logic         m_wait = 1'b0, m_rvalid = 1'b0;
    logic  [31:0] m_rdata = 32'd0;
    logic        o_de, o_hs, o_vs;
    logic [3:0]  o_piks;

    bufor_ramki #(.SZER(SZER), .WYS(WYS), .SK(1), .BURST(4), .AW(16), .BAZA0(0), .BAZA1(RAMKA)) dut (
        .clk_m(clk_m), .rst_m(rst_m), .przelacz(przelacz), .aktywny(aktywny), .oczekuje(oczekuje), .brak(brak),
        .m_adr(m_adr), .m_read(m_read), .m_burstcount(m_burstcount), .m_wait(m_wait), .m_rvalid(m_rvalid),
        .m_rdata(m_rdata),
        .clk_p(clk_p), .rst_p(rst_p), .de(de), .hs(hs), .vs(vs), .x(x), .y(y),
        .o_de(o_de), .o_hs(o_hs), .o_vs(o_vs), .o_piks(o_piks));

    // wzór piksela: ramka f (0 = A, 1 = B), współrzędne obrazu (px, py)
    function [3:0] wzor(input int f, input int px, input int py);
        wzor = (f * 7 + px * 3 + py * 5 + 1) % 16;
    endfunction

    // ---- pamięć: 2 ramki
    logic [31:0] pam [0:2*RAMKA-1];
    int f, w, p, i;
    initial
        for (f = 0; f < 2; f = f + 1)
            for (w = 0; w < RAMKA; w = w + 1)
                for (p = 0; p < 8; p = p + 1)
                    pam[f * RAMKA + w][4 * p +: 4] = wzor(f, (w % SLOW) * 8 + p, w / SLOW);

    // ---- model slave'a Avalon-MM z burstami: kolejka rozkazów, opóźnienie ≥ 3 takty
    int seed = 77, kz = 0, ko = 0, n_burst = 0, n_slow = 0;
    logic [15:0] k_adr [0:15];
    logic [4:0]  k_dl  [0:15];
    int    k_t   [0:15];
    int    takt_m = 0, ile_w = 0;
    always @(negedge clk_m) m_wait <= (($random(seed) & 32'h7fffffff) % 100) < 30;
    always @(posedge clk_m) begin
        takt_m = takt_m + 1;
        if (m_read && !m_wait) begin
            k_adr[kz % 16] = m_adr; k_dl[kz % 16] = m_burstcount; k_t[kz % 16] = takt_m;
            kz = kz + 1; n_burst = n_burst + 1;
        end
        m_rvalid <= 1'b0;
        if (ko != kz && takt_m - k_t[ko % 16] >= 3 && (($random(seed) & 32'h7fffffff) % 100) >= 20) begin
            m_rvalid <= 1'b1;
            m_rdata  <= pam[k_adr[ko % 16] + ile_w];
            n_slow = n_slow + 1;
            if (ile_w + 1 == k_dl[ko % 16]) begin ile_w = 0; ko = ko + 1; end
            else ile_w = ile_w + 1;
        end
    end

    // ---- czas ładowania linii (start -> gotowe), w ns
    realtime t_cz = 0, max_cz = 0;
    always @(posedge clk_m) begin
        if (dut.cz_start) t_cz = $realtime;
        if (dut.cz_gotowe && $realtime - t_cz > max_cz) max_cz = $realtime - t_cz;
    end

    // ---- klasyfikacja wyświetlonych ramek
    int ox = 0, oy = 0, n_pix = 0, zg0 = 0, zg1 = 0, czarne = 0, nr = 0, bl_linii = 0;
    logic     vs_d = 1'b0, de_d = 1'b0;
    logic [8*8-1:0] klasa [0:9];
    logic [8*8-1:0] k;
    always @(posedge clk_p) begin
        if (o_de) begin
            if (o_piks == wzor(0, ox / 2, oy / 2)) zg0 = zg0 + 1;
            if (o_piks == wzor(1, ox / 2, oy / 2)) zg1 = zg1 + 1;
            if (o_piks == 4'd0) czarne = czarne + 1;
            ox = ox + 1; n_pix = n_pix + 1;
        end
        if (de_d && !o_de) begin
            if (ox != 96) bl_linii = bl_linii + 1;
            ox = 0; oy = oy + 1;
        end
        if (o_vs && !vs_d) begin                                     // koniec ramki
            k = (n_pix != 96 * 12) ? "rozmiar" : (czarne == n_pix) ? "czarna" : (zg0 == n_pix) ? "A" :
                (zg1 == n_pix) ? "B" : "mieszana";
            if (nr < 10) klasa[nr] = k;
            $display("ramka %0d: %0s (pikseli %0d, zgodnych z A %0d, z B %0d), aktywny = %b", nr, k, n_pix, zg0, zg1, aktywny);
            nr = nr + 1; oy = 0; n_pix = 0; zg0 = 0; zg1 = 0; czarne = 0;
        end
        vs_d = o_vs; de_d = o_de;
    end

    initial begin
        repeat (4) @(posedge clk_m);
        rst_m = 1'b0;
        @(posedge clk_p) rst_p = 1'b0;
        for (i = 0; i < 7; i = i + 1) begin
            wait (nr == i);
            if (i == 2 || i == 4) begin                              // połowa ramki: zgłoś zamianę
                wait (o_de && oy == 6);
                @(negedge clk_m) przelacz = 1'b1;
                @(negedge clk_m) przelacz = 1'b0;
            end
        end
        wait (nr == 7);
        if (klasa[0] != "czarna" || klasa[1] != "A" || klasa[2] != "A" || klasa[3] != "B" || klasa[4] != "B" ||
            klasa[5] != "A" || klasa[6] != "A") errors = errors + 1;
        $display("burstow %0d, slow %0d (%0d na ramke), najdluzsze ladowanie linii %.0f ns, linia wyswietlana %0d ns",
                 n_burst, n_slow, RAMKA, max_cz, 112 * 40);
        $display("brak = %b, oczekuje = %b, bledne linie %0d", brak, oczekuje, bl_linii);
        if (brak || oczekuje || bl_linii != 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
