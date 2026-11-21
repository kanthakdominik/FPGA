// Testbench (SystemVerilog) 24.06: takt_wideo + filtr3x3 na obrazie 24×10 (linia z wygaszaniem L = 30, ramka 13 linii).
// 12 ramek, tryb = numer ramki mod 4 (zmiana w wygaszaniu pionowym): obrazy — gradient, szachownica 0/255
// (nasycenie Sobela), losowe. W wygaszaniu na wejście piksela podawane są śmieci (filtr ma je pomijać).
// Każdy piksel wyjścia porównany z modelem w testbenchu (splot z uzupełnieniem zerami); de/hs/vs wyjścia
// porównane z wejściowymi opóźnionymi o L + 4 takty.
`timescale 1ns / 1ps
`default_nettype none

module tb_filtr;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    int errors = 0;

    localparam int W = 24, H = 10, L = 30, OP = L + 4;

    logic        hs, vs, de, nowa_ramka;
    logic [11:0] x, y;
    takt_wideo #(.H_AKT(W), .H_FP(2), .H_SYNC(2), .H_BP(2), .V_AKT(H), .V_FP(1), .V_SYNC(1), .V_BP(1),
                 .H_POL(1'b1), .V_POL(1'b1))
        u_takt (.clk(clk), .rst(rst), .hs(hs), .vs(vs), .de(de), .x(x), .y(y), .nowa_ramka(nowa_ramka));

    logic  [1:0] tryb = 2'd0;
    logic  [7:0] piks;
    logic       o_de, o_hs, o_vs;
    logic [7:0] o_piks;
    filtr3x3 #(.L(L), .PROG(128)) dut (.clk(clk), .tryb(tryb), .de(de), .hs(hs), .vs(vs), .piks(piks),
                                       .o_de(o_de), .o_hs(o_hs), .o_vs(o_vs), .o_piks(o_piks));

    int img [0:H-1][0:W-1];
    int seed = 6, fr = 0, i, j;

    task nowy_obraz(input int f);
        begin
            for (j = 0; j < H; j = j + 1)
                for (i = 0; i < W; i = i + 1)
                    case (f % 3)
                        0: img[j][i] = (i * 10 + j * 7) % 256;
                        1: img[j][i] = (((i / 2) + (j / 2)) % 2) ? 255 : 0;
                        default: img[j][i] = ($random(seed) & 32'h7fffffff) % 256;
                    endcase
        end
    endtask

    function int p(input int xx, input int yy);
        p = (xx < 0 || xx >= W || yy < 0 || yy >= H) ? 0 : img[yy][xx];
    endfunction
    function int ocz(input int t, input int xx, input int yy);
        int gx, gy, s;
        begin
            gx = p(xx+1, yy-1) + 2 * p(xx+1, yy) + p(xx+1, yy+1) - p(xx-1, yy-1) - 2 * p(xx-1, yy) - p(xx-1, yy+1);
            gy = p(xx-1, yy+1) + 2 * p(xx, yy+1) + p(xx+1, yy+1) - p(xx-1, yy-1) - 2 * p(xx, yy-1) - p(xx+1, yy-1);
            s  = (gx < 0 ? -gx : gx) + (gy < 0 ? -gy : gy);
            case (t)
                0: ocz = p(xx, yy);
                1: ocz = (p(xx-1, yy-1) + 2 * p(xx, yy-1) + p(xx+1, yy-1) + 2 * p(xx-1, yy) + 4 * p(xx, yy)
                        + 2 * p(xx+1, yy) + p(xx-1, yy+1) + 2 * p(xx, yy+1) + p(xx+1, yy+1) + 8) / 16;
                2: ocz = (s > 255) ? 255 : s;
                default: ocz = (s >= 128) ? 255 : 0;
            endcase
        end
    endfunction

    // wejście piksela: obraz w obszarze aktywnym, śmieci w wygaszaniu
    always @(*) piks = de ? img[y][x] : 8'hA5 ^ x[7:0];

    // historia synchronizacji wejścia
    logic [2:0] hist [0:63];
    int   t = 0, bl_syn = 0, bl_pix = 0, n_pix = 0, ox = 0, oy = 0, n_sob_nas = 0, n_kraw = 0;
    logic       vs_d = 1'b0, ode_d = 1'b0, ovs_d = 1'b0;
    int   tryb_wy = 0;
    always @(posedge clk) if (!rst) begin
        hist[t % 64] = {de, hs, vs};
        if (t >= OP && {o_de, o_hs, o_vs} !== hist[(t - OP) % 64]) bl_syn = bl_syn + 1;
        t = t + 1;
    end

    // wyjście: współrzędne i porównanie
    always @(posedge clk) if (!rst) begin
        if (o_de) begin
            if (o_piks !== ocz(tryb_wy, ox, oy)) begin
                if (bl_pix < 5) $display("ramka %0d tryb %0d (%0d,%0d): %0d, oczekiwano %0d", fr, tryb_wy, ox, oy, o_piks, ocz(tryb_wy, ox, oy));
                bl_pix = bl_pix + 1;
            end
            if (tryb_wy == 2 && o_piks == 255) n_sob_nas = n_sob_nas + 1;
            if (tryb_wy == 3 && o_piks == 255) n_kraw = n_kraw + 1;
            n_pix = n_pix + 1;
            ox = ox + 1;
        end
        if (ode_d && !o_de) begin ox = 0; oy = oy + 1; end
        if (o_vs && !ovs_d) oy = 0;
        ode_d = o_de; ovs_d = o_vs;
    end

    initial begin
        nowy_obraz(0);
        repeat (3) @(negedge clk);
        rst = 1'b0;
        // zmiana obrazu i trybu na początku impulsu VS wejścia (wyjście ramki skończone linię wcześniej)
        while (fr < 12) begin
            @(posedge clk);
            if (vs && !vs_d) begin
                @(negedge clk);
                fr = fr + 1;
                nowy_obraz(fr);
                tryb = fr % 4;
                tryb_wy = fr % 4;
            end
            vs_d = vs;
        end
        $display("ramek %0d, pikseli sprawdzonych %0d, bledow pikseli %0d, bledow synchronizacji %0d",
                 fr, n_pix, bl_pix, bl_syn);
        $display("Sobel nasycony (255): %0d pikseli; krawedzie (prog 128): %0d pikseli; opoznienie %0d taktow",
                 n_sob_nas, n_kraw, OP);
        if (bl_pix != 0 || bl_syn != 0 || n_pix != 12 * W * H || n_sob_nas == 0 || n_kraw == 0) errors = errors + 1;
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
