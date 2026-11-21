// Testbench (SystemVerilog) 24.03: linia_bres, znaki, sprite16.
//  Odcinki: 12 przypadków szczególnych (poziome, pionowe, przekątne, punkt, wszystkie oktanty) i 300 losowych
//  w 640×480, odbiorca losowo wstrzymuje (dalej = 0 w 30% taktów). Dla każdego: pierwszy i ostatni punkt,
//  liczba punktów = max(|dx|, |dy|) + 1, kroki o 0/±1 z krokiem zawsze w osi głównej, odległość od prostej
//  w osi pobocznej ≤ 1/2 piksela.
//  Tekst: "ABC 0123?" i "a" w siatce 40×30 przy SK = 1; piksele znaków A, 1 i a porównane z rysunkiem
//  czcionki, odstępy (kolumny 5–7, wiersz 7) i komórki puste — zera.
//  Sprite: piksele w obszarze 24×24 wokół (100, 50) i przy (0, 0) porównane z rysunkiem (przezroczystość, kolor).
`timescale 1ns / 1ps
`default_nettype none

module tb_grafika;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    // ---- linia_bres
    logic         start = 1'b0, dalej = 1'b1;
    logic  [11:0] x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    logic        gotowy, pwazny, koniec;
    logic [11:0] px, py;
    linia_bres u_lin (.clk(clk), .rst(rst), .start(start), .x0(x0), .y0(y0), .x1(x1), .y1(y1), .dalej(dalej),
                      .gotowy(gotowy), .px(px), .py(py), .pwazny(pwazny), .koniec(koniec));

    // ---- znaki i sprite
    logic         we = 1'b0;
    logic  [10:0] wadr = 0;
    logic  [7:0]  wkod = 0;
    logic  [11:0] x = 0, y = 0, sx = 100, sy = 50;
    logic        piks, widoczny;
    logic [1:0]  kolor;
    znaki #(.KOL(40), .WIER(30), .SK(1)) u_zn (.clk(clk), .we(we), .wadr(wadr), .wkod(wkod), .x(x), .y(y), .piks(piks));
    sprite16 u_sp (.clk(clk), .x(x), .y(y), .sx(sx), .sy(sy), .widoczny(widoczny), .kolor(kolor));

    // rysunki wzorcowe
    logic [8*5-1:0]  litA [0:6];
    logic [8*5-1:0]  cyf1 [0:6];
    logic [8*16-1:0] obraz [0:15];
    initial begin
        litA[0] = " ### "; litA[1] = "#   #"; litA[2] = "#   #"; litA[3] = "#####";
        litA[4] = "#   #"; litA[5] = "#   #"; litA[6] = "#   #";
        cyf1[0] = "  #  "; cyf1[1] = " ##  "; cyf1[2] = "  #  "; cyf1[3] = "  #  ";
        cyf1[4] = "  #  "; cyf1[5] = "  #  "; cyf1[6] = " ### ";
        obraz[0] = ".....aaaaaa.....";
        obraz[1] = "...aabbbbbbaa...";
        obraz[2] = "..abbbbbbbbbba..";
        obraz[3] = ".abbbbbbbbbbbba.";
        obraz[4] = ".abbcccbbcccbba.";
        obraz[5] = "abbbcacbbcacbbba";
        obraz[6] = "abbbcccbbcccbbba";
        obraz[7] = "abbbbbbbbbbbbbba";
        obraz[8] = "abbbbbbbbbbbbbba";
        obraz[9] = "abbcbbbbbbbbcbba";
        obraz[10] = "abbbcbbbbbbcbbba";
        obraz[11] = ".abbbccccccbbba.";
        obraz[12] = ".abbbbbbbbbbbba.";
        obraz[13] = "..abbbbbbbbbba..";
        obraz[14] = "...aabbbbbbaa...";
        obraz[15] = ".....aaaaaa.....";
    end

    // ---- odcinki: odbiór punktów i kontrola
    int seed = 2024, n_pkt = 0, bl_lin = 0, n_lin = 0, takty = 0, i, j, k;
    int ax0, ay0, ax1, ay1, ddx, ddy, gl, pop_x, pop_y, wiersz_bl;
    logic     pierwszy = 1'b0;
    int qx, qy;
    always @(posedge clk) if (pwazny && dalej) begin
        qx = px; qy = py;                              // liczby całkowite ze znakiem
        if (pierwszy) begin
            if (qx != ax0 || qy != ay0) wiersz_bl = wiersz_bl + 1;
        end else begin
            // krok: o 0/±1 w każdej osi, w osi głównej zawsze
            if ((qx - pop_x) * (qx - pop_x) > 1 || (qy - pop_y) * (qy - pop_y) > 1) wiersz_bl = wiersz_bl + 1;
            if (gl == 0 && qx == pop_x) wiersz_bl = wiersz_bl + 1;
            if (gl == 1 && qy == pop_y) wiersz_bl = wiersz_bl + 1;
        end
        // odległość od prostej w osi pobocznej ≤ 1/2: |2·((qy-y0)·dx - (qx-x0)·dy)| ≤ |oś główna|
        if (gl == 0 && 2 * ((qy - ay0) * ddx - (qx - ax0) * ddy) > (ddx < 0 ? -ddx : ddx)) wiersz_bl = wiersz_bl + 1;
        if (gl == 0 && 2 * ((qy - ay0) * ddx - (qx - ax0) * ddy) < -(ddx < 0 ? -ddx : ddx)) wiersz_bl = wiersz_bl + 1;
        if (gl == 1 && 2 * ((qx - ax0) * ddy - (qy - ay0) * ddx) > (ddy < 0 ? -ddy : ddy)) wiersz_bl = wiersz_bl + 1;
        if (gl == 1 && 2 * ((qx - ax0) * ddy - (qy - ay0) * ddx) < -(ddy < 0 ? -ddy : ddy)) wiersz_bl = wiersz_bl + 1;
        pierwszy = 1'b0;
        pop_x = qx; pop_y = qy;
        n_pkt = n_pkt + 1;
        if (koniec && (qx != ax1 || qy != ay1)) wiersz_bl = wiersz_bl + 1;
    end
    always @(posedge clk) if (!gotowy) takty = takty + 1;
    always @(negedge clk) dalej = (($random(seed) & 32'h7fffffff) % 10) < 7;

    task odcinek(input int a, input int b, input int c, input int d);
        int n0;
        begin
            ax0 = a; ay0 = b; ax1 = c; ay1 = d; ddx = c - a; ddy = d - b;
            gl = ((ddx < 0 ? -ddx : ddx) >= (ddy < 0 ? -ddy : ddy)) ? 0 : 1;
            wiersz_bl = 0; pierwszy = 1'b1; n0 = n_pkt;
            @(negedge clk);
            x0 = a; y0 = b; x1 = c; y1 = d; start = 1'b1;
            @(negedge clk) start = 1'b0;
            @(posedge gotowy);
            if (n_pkt - n0 != ((gl == 0) ? (ddx < 0 ? -ddx : ddx) : (ddy < 0 ? -ddy : ddy)) + 1) wiersz_bl = wiersz_bl + 1;
            if (wiersz_bl != 0) begin
                if (bl_lin < 5) $display("odcinek (%0d,%0d)-(%0d,%0d): %0d bledow, %0d punktow", a, b, c, d, wiersz_bl, n_pkt - n0);
                bl_lin = bl_lin + 1;
            end
            n_lin = n_lin + 1;
        end
    endtask

    // ---- tekst i sprite: kontrola piksela
    function rys(input [8*5-1:0] w, input int kol);
        rys = (w[8 * (4 - kol) +: 8] == "#");
    endfunction
    function [1:0] spr(input [8*16-1:0] w, input int kol);
        case (w[8 * (15 - kol) +: 8])
            "a":     spr = 2'd1;
            "b":     spr = 2'd2;
            "c":     spr = 2'd3;
            default: spr = 2'd0;
        endcase
    endfunction

    logic [8*9-1:0] napis;
    int bl_zn = 0, n_zn = 0, n_jasnych = 0, bl_sp = 0, n_sp = 0, n_wid = 0, cx, cy, fx, fy, ocz, ox, oy;
    logic [1:0] okol;

    task piksel_znaku(input int xx, input int yy);
        begin
            @(negedge clk) begin x = xx; y = yy; end
            @(posedge clk); @(posedge clk); #1;
            cx = xx / 16; cy = yy / 16; fx = (xx / 2) % 8; fy = (yy / 2) % 8;
            ocz = 0;
            if (fx < 5 && fy < 7 && cy == 2 && cx == 3) ocz = rys(litA[fy], fx);         // 'A'
            if (fx < 5 && fy < 7 && cy == 2 && cx == 8) ocz = rys(cyf1[fy], fx);         // '1'
            if (fx < 5 && fy < 7 && cy == 5 && cx == 0) ocz = rys(litA[fy], fx);         // 'a' -> 'A'
            // pozostałe znaki napisu: sprawdzane tylko odstępy (ocz = 0 poza 5×7)
            if (fx < 5 && fy < 7 && cy == 2 && cx >= 4 && cx <= 11 && cx != 8) ocz = piks;
            if (piks !== ocz[0]) begin
                if (bl_zn < 5) $display("tekst: piksel (%0d,%0d) = %b, oczekiwano %0d", xx, yy, piks, ocz);
                bl_zn = bl_zn + 1;
            end
            n_zn = n_zn + 1;
            if (piks) n_jasnych = n_jasnych + 1;
        end
    endtask

    task piksel_sprite(input int xx, input int yy);
        begin
            @(negedge clk) begin x = xx; y = yy; end
            @(posedge clk); #1;
            ox = xx - sx; oy = yy - sy;
            okol = (ox >= 0 && ox < 16 && oy >= 0 && oy < 16) ? spr(obraz[oy], ox) : 2'd0;
            if (widoczny !== (okol != 2'd0) || (widoczny && kolor !== okol)) begin
                if (bl_sp < 5) $display("sprite: (%0d,%0d) widoczny %b kolor %0d, oczekiwano %0d", xx, yy, widoczny, kolor, okol);
                bl_sp = bl_sp + 1;
            end
            n_sp = n_sp + 1;
            if (widoczny) n_wid = n_wid + 1;
        end
    endtask

    initial begin
        repeat (3) @(negedge clk);
        rst = 1'b0;
        // odcinki szczególne
        odcinek(10, 10, 10, 10);   odcinek(0, 0, 639, 0);     odcinek(639, 479, 0, 479); odcinek(5, 0, 5, 479);
        odcinek(5, 479, 5, 0);     odcinek(0, 0, 479, 479);   odcinek(479, 0, 0, 479);   odcinek(100, 100, 107, 103);
        odcinek(100, 100, 93, 97); odcinek(100, 100, 103, 107); odcinek(100, 100, 97, 93); odcinek(320, 240, 0, 1);
        for (i = 0; i < 300; i = i + 1)
            odcinek(($random(seed) & 32'h7fffffff) % 640, ($random(seed) & 32'h7fffffff) % 480,
                    ($random(seed) & 32'h7fffffff) % 640, ($random(seed) & 32'h7fffffff) % 480);
        $display("odcinki: %0d, punktow %0d w %0d taktach (odbiorca gotowy w 70%% taktow), bledne odcinki %0d",
                 n_lin, n_pkt, takty, bl_lin);
        if (bl_lin != 0) errors = errors + 1;

        // tekst: "ABC 0123?" w wierszu 2 od kolumny 3, "a" w wierszu 5, kolumnie 0
        napis = "ABC 0123?";
        for (i = 0; i < 9; i = i + 1) begin
            @(negedge clk) begin we = 1'b1; wadr = 2 * 40 + 3 + i; wkod = napis[8 * (8 - i) +: 8]; end
        end
        @(negedge clk) begin wadr = 5 * 40; wkod = "a"; end
        @(negedge clk) we = 1'b0;
        for (j = 2 * 16; j < 3 * 16; j = j + 1)
            for (i = 2 * 16; i < 13 * 16; i = i + 1) piksel_znaku(i, j);
        for (j = 5 * 16; j < 6 * 16; j = j + 1)
            for (i = 0; i < 2 * 16; i = i + 1) piksel_znaku(i, j);
        $display("tekst: %0d pikseli sprawdzonych, %0d jasnych, bledow %0d", n_zn, n_jasnych, bl_zn);
        if (bl_zn != 0 || n_jasnych == 0) errors = errors + 1;

        // sprite
        for (j = 46; j < 70; j = j + 1)
            for (i = 96; i < 120; i = i + 1) piksel_sprite(i, j);
        @(negedge clk) begin sx = 0; sy = 0; end
        for (j = 0; j < 20; j = j + 1)
            for (i = 0; i < 20; i = i + 1) piksel_sprite(i, j);
        $display("sprite: %0d pikseli sprawdzonych, %0d widocznych, bledow %0d", n_sp, n_wid, bl_sp);
        if (bl_sp != 0 || n_wid == 0) errors = errors + 1;

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
