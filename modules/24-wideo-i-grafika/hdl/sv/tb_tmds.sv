// Testbench (SystemVerilog) 24.02: tmds_kod. Strumień 300 000 symboli w „liniach” (64 piksele aktywne, 16 wygaszania ze znakami
// sterującymi), dane losowe i wzorce skrajne (00, FF, 55, AA, 0F). Sprawdza: dekodowanie każdego symbolu danych
// (dekoder w testbenchu), znaki sterujące dla c = 00..11, nierównowagę strumienia w obszarze aktywnym
// (|jedynki - zera| ≤ 8 od początku linii), liczbę zmian: ≤ 5 w symbolu danych, ≥ 7 w znaku sterującym.
`timescale 1ns / 1ps
`default_nettype none

module tb_tmds;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    logic  [7:0] d = 8'd0;
    logic  [1:0] c = 2'd0;
    logic        de = 1'b0;
    logic [9:0] q;

    tmds_kod dut (.clk(clk), .rst(rst), .d(d), .c(c), .de(de), .q(q));

    function [7:0] dekod(input [9:0] s);
        logic [7:0] v;
        int i;
        begin
            v = s[9] ? ~s[7:0] : s[7:0];
            dekod[0] = v[0];
            for (i = 1; i < 8; i = i + 1) dekod[i] = s[8] ? (v[i] ^ v[i-1]) : ~(v[i] ^ v[i-1]);
        end
    endfunction
    function int zmiany(input [9:0] s);
        int i;
        begin
            zmiany = 0;
            for (i = 0; i < 9; i = i + 1) if (s[i] != s[i+1]) zmiany = zmiany + 1;
        end
    endfunction
    function int jedynki10(input [9:0] s);
        int i;
        begin
            jedynki10 = 0;
            for (i = 0; i < 10; i = i + 1) jedynki10 = jedynki10 + s[i];
        end
    endfunction
    function [9:0] steruj(input [1:0] cc);
        case (cc)
            2'b00:   steruj = 10'b1101010100;
            2'b01:   steruj = 10'b0010101011;
            2'b10:   steruj = 10'b0101010100;
            default: steruj = 10'b1010101011;
        endcase
    endfunction

    // historia wejść (indeks n mod 4); wynik dla wejścia n widoczny przy zboczu opadającym n + 2
    logic [7:0] h_d  [0:3];
    logic [1:0] h_c  [0:3];
    logic       h_de [0:3];
    logic       kody [0:1023];
    int   n, seed = 24, nier = 0, max_nier = 0, max_zm_d = 0, min_zm_s = 99, n_dane = 0, n_ster = 0;
    int   bl_dek = 0, bl_ster = 0, rozne = 0, w, z;

    initial begin
        for (n = 0; n < 1024; n = n + 1) kody[n] = 1'b0;
        for (n = 0; n < 4; n = n + 1) begin h_d[n] = 0; h_c[n] = 0; h_de[n] = 0; end
        repeat (3) @(negedge clk);
        rst = 1'b0;
        for (n = 0; n < 300000 + 2; n = n + 1) begin
            @(negedge clk);
            // kontrola wyniku dla wejścia n - 2
            if (n >= 2) begin
                w = (n - 2) % 4;
                if (h_de[w]) begin
                    n_dane = n_dane + 1;
                    if (dekod(q) !== h_d[w]) begin
                        if (bl_dek < 5) $display("dekodowanie: d = %h, q = %b -> %h", h_d[w], q, dekod(q));
                        bl_dek = bl_dek + 1;
                    end
                    nier = nier + 2 * jedynki10(q) - 10;
                    if (nier > max_nier) max_nier = nier;
                    if (-nier > max_nier) max_nier = -nier;
                    z = zmiany(q);
                    if (z > max_zm_d) max_zm_d = z;
                    if (!kody[q]) begin kody[q] = 1'b1; rozne = rozne + 1; end
                end else begin
                    n_ster = n_ster + 1;
                    nier = 0;                                    // nowa linia: licznik kodera wraca do zera
                    if (q !== steruj(h_c[w])) bl_ster = bl_ster + 1;
                    z = zmiany(q);
                    if (z < min_zm_s) min_zm_s = z;
                end
            end
            // nowe wejście n
            de = (n % 80) < 64;
            if ((n / 80) % 7 == 3) d = (n % 5 == 0) ? 8'h00 : (n % 5 == 1) ? 8'hFF : (n % 5 == 2) ? 8'h55 :
                                       (n % 5 == 3) ? 8'hAA : 8'h0F;
            else d = $random(seed);
            c = $random(seed);
            h_d[n % 4] = d; h_c[n % 4] = c; h_de[n % 4] = de;
        end
        $display("symboli danych %0d, sterujacych %0d; bledow dekodowania %0d, zlych znakow sterujacych %0d",
                 n_dane, n_ster, bl_dek, bl_ster);
        $display("roznych slow kodowych danych: %0d; max |jedynki - zera| w linii: %0d", rozne, max_nier);
        $display("zmian w symbolu: dane maks. %0d, znaki sterujace min. %0d", max_zm_d, min_zm_s);
        if (bl_dek != 0 || bl_ster != 0) errors = errors + 1;
        if (max_nier > 8)  errors = errors + 1;
        if (max_zm_d > 5)  errors = errors + 1;
        if (min_zm_s < 7)  errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
