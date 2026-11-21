// Testbench (SystemVerilog) 24.01: takt_wideo w trzech trybach — 640×480 przy 60 Hz (VESA, impulsy ujemne), 1280×720 przy 60 Hz
// (CEA-861, impulsy dodatnie) i mały tryb próbny. Kontroler spr_takt mierzy na wyjściach: liczbę pikseli aktywnych
// w linii, szerokości i położenie impulsów, okres linii i ramki, liczbę linii aktywnych, zgodność x/y z pozycją
// oraz impuls nowa_ramka na pierwszym pikselu aktywnym.
`timescale 1ns / 1ps
`default_nettype none

module spr_takt #(
    parameter [8*12-1:0] NAZWA = "tryb",
    parameter int H_AKT = 640, H_FP = 16, H_SYNC = 96, H_BP = 48,
    parameter int V_AKT = 480, V_FP = 10, V_SYNC = 2, V_BP = 33,
    parameter H_POL = 1'b0, V_POL = 1'b0,
    parameter int RAMEK = 2,
    parameter int OKRES_PS = 39722              // okres zegara piksela [ps] — do wypisania odświeżania
) (
    output logic  koniec = 1'b0,
    output logic [31:0] bledy = 0
);
    logic clk = 1'b0;
    always #(OKRES_PS / 2000.0) clk = ~clk;
    logic rst = 1'b1;
    logic hs, vs, de, nowa_ramka;
    logic [11:0] x, y;

    takt_wideo #(.H_AKT(H_AKT), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP), .V_AKT(V_AKT), .V_FP(V_FP),
                 .V_SYNC(V_SYNC), .V_BP(V_BP), .H_POL(H_POL), .V_POL(V_POL))
        dut (.clk(clk), .rst(rst), .hs(hs), .vs(vs), .de(de), .x(x), .y(y), .nowa_ramka(nowa_ramka));

    localparam int H_TOT = H_AKT + H_FP + H_SYNC + H_BP;
    localparam int V_TOT = V_AKT + V_FP + V_SYNC + V_BP;

    int t = 0, hc = 0, vc = 0, ramka = -1;
    int de_w_linii = 0, hs_w_linii = 0, hs_start = -1, linie_akt = 0, vs_linie = 0, vs_start = -1;
    int pocz_ramki = -1, okres_ramki = 0, bl_xy = 0, bl_nr = 0;
    logic     de_l = 1'b0, vs_akt = 1'b0;
    logic    hs_a;
    assign hs_a = (hs == H_POL);
    logic    vs_a;
    assign vs_a = (vs == V_POL);

    task blad(input [8*48-1:0] co, input int jest, input int ma);
        begin
            if (bledy < 10) $display("  %s: %s = %0d, oczekiwano %0d (linia %0d, ramka %0d)", NAZWA, co, jest, ma, vc, ramka);
            bledy = bledy + 1;
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;
    end

    // pozycja (hc, vc) liczona przez testbench od pierwszego impulsu nowa_ramka
    always @(posedge clk) if (!rst) begin
        if (nowa_ramka) begin
            if (ramka >= 0 && (hc != H_TOT - 1 || vc != V_TOT - 1)) blad("koniec ramki przed nowa_ramka", hc, H_TOT - 1);
            if (pocz_ramki >= 0) okres_ramki = t - pocz_ramki;
            if (ramka >= 0 && okres_ramki != H_TOT * V_TOT) blad("okres ramki w taktach", okres_ramki, H_TOT * V_TOT);
            if (ramka >= 0 && linie_akt != V_AKT) blad("linie aktywne", linie_akt, V_AKT);
            if (ramka >= 0 && vs_linie != V_SYNC) blad("szerokosc VS w liniach", vs_linie, V_SYNC);
            if (ramka >= 0 && vs_start != V_AKT + V_FP) blad("poczatek VS (linia)", vs_start, V_AKT + V_FP);
            pocz_ramki = t; ramka = ramka + 1; hc = 0; vc = 0;
            linie_akt = 0; vs_linie = 0; vs_start = -1;
            if (!de || x != 0 || y != 0) blad("nowa_ramka poza pikselem (0,0)", x, 0);
        end else if (ramka >= 0) begin
            if (hc == H_TOT - 1) begin hc = 0; vc = vc + 1; end
            else hc = hc + 1;
        end
        if (ramka >= 0) begin
            if (de != (hc < H_AKT && vc < V_AKT)) bl_nr = bl_nr + 1;
            if (x != hc || y != vc) bl_xy = bl_xy + 1;
            if (hc == 0) begin                                       // początek linii: podsumowanie poprzedniej
                de_w_linii = 0; hs_w_linii = 0; hs_start = -1;
                if (vs_a && !vs_akt) vs_start = vc;
                if (vs_a) vs_linie = vs_linie + 1;
                vs_akt = vs_a;
                if (de) linie_akt = linie_akt + 1;
            end
            if (de) de_w_linii = de_w_linii + 1;
            if (hs_a) begin
                if (hs_start < 0) hs_start = hc;
                hs_w_linii = hs_w_linii + 1;
            end
            if (vs_a && hc != 0 && !vs_akt) blad("VS zmienia sie w srodku linii", hc, 0);
            if (hc == H_TOT - 1) begin
                if (vc < V_AKT && de_w_linii != H_AKT) blad("piksele aktywne w linii", de_w_linii, H_AKT);
                if (vc >= V_AKT && de_w_linii != 0) blad("piksele aktywne w wygaszaniu", de_w_linii, 0);
                if (hs_w_linii != H_SYNC) blad("szerokosc HS", hs_w_linii, H_SYNC);
                if (hs_start != H_AKT + H_FP) blad("poczatek HS", hs_start, H_AKT + H_FP);
            end
        end
        t = t + 1;
    end

    initial begin
        wait (ramka == RAMEK);
        if (bl_xy != 0) blad("niezgodne x/y", bl_xy, 0);
        if (bl_nr != 0) blad("de poza obszarem aktywnym", bl_nr, 0);
        $display("  %s: linia %0d taktow (HS %0d od %0d), ramka %0d linii = %0d taktow, %0d ramek: %0d bledow",
                 NAZWA, H_TOT, H_SYNC, H_AKT + H_FP, V_TOT, H_TOT * V_TOT, RAMEK, bledy);
        $display("    odswiezanie %.3f Hz, linia %.3f kHz przy %.3f MHz",
                 1.0e12 / (OKRES_PS * 1.0 * H_TOT * V_TOT), 1.0e9 / (OKRES_PS * 1.0 * H_TOT), 1.0e6 / OKRES_PS);
        koniec = 1'b1;
    end
endmodule

module tb_takt;
    logic k1, k2, k3;
    logic [31:0] b1, b2, b3;

    // VESA DMT 640×480 @ 60 Hz: 25,175 MHz, 800 × 525, HS i VS ujemne
    spr_takt #(.NAZWA("640x480"), .RAMEK(2), .OKRES_PS(39722)) m640 (.koniec(k1), .bledy(b1));
    // CEA-861 1280×720 @ 60 Hz: 74,25 MHz, 1650 × 750, HS i VS dodatnie
    spr_takt #(.NAZWA("1280x720"), .H_AKT(1280), .H_FP(110), .H_SYNC(40), .H_BP(220),
               .V_AKT(720), .V_FP(5), .V_SYNC(5), .V_BP(20), .H_POL(1'b1), .V_POL(1'b1),
               .RAMEK(1), .OKRES_PS(13468)) m720 (.koniec(k2), .bledy(b2));
    // mały tryb próbny: impulsy na granicach (FP = 1, BP = 1)
    spr_takt #(.NAZWA("maly"), .H_AKT(8), .H_FP(1), .H_SYNC(2), .H_BP(1),
               .V_AKT(4), .V_FP(1), .V_SYNC(1), .V_BP(1), .H_POL(1'b1), .V_POL(1'b0),
               .RAMEK(5), .OKRES_PS(10000)) mmaly (.koniec(k3), .bledy(b3));

    initial begin
        wait (k1 && k2 && k3);
        if (b1 + b2 + b3 == 0) $display("PASS");
        else                   $display("FAIL: %0d bledow", b1 + b2 + b3);
        $finish;
    end
endmodule

`default_nettype wire
