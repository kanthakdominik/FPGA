// Testbench (SystemVerilog) projektu 5 (31.05): obraz 64×32 (linia 72 takty), scena stała (ruch = 0). Dla każdego trybu cała
// ramka jest zapisywana i porównywana z modelem sceny: tam, gdzie okno 3×3 (dla filtrów 5×5) leży w jednym
// obszarze sceny — w pasie koloru, w kwadracie albo w gradiencie liniowym — demozaikowanie dwuliniowe musi
// odtworzyć kolor dokładnie, a filtr dać wynik znany analitycznie. Sprawdzana jest też suma jasności ramki.
`timescale 1ns / 1ps
`default_nettype none

module tb_projekt_obraz;
    localparam int W = 64, H = 32, PROG = 20;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    logic rst = 1'b1;
    logic [2:0] tryb = 3'd0;
    logic de, hs, vs;
    logic [23:0] rgb;
    logic [31:0] suma_y;
    int errors = 0;

    projekt_obraz #(.H_AKT(W), .H_FP(2), .H_SYNC(4), .H_BP(2), .V_AKT(H), .V_FP(1), .V_SYNC(2), .V_BP(1),
                    .PROG(PROG)) dut (.clk(clk), .rst(rst), .tryb(tryb), .ruch(1'b0), .de(de), .hs(hs), .vs(vs),
                    .rgb(rgb), .suma_y(suma_y));

    // ---- model sceny (jak wzor_bayer przy ruch = 0: kwadrat 8×8 w (0, H/2))
    function int obszar(input int x, input int y);       // 0..7 pasy, 8 kwadrat, 9 gradient
        if (x < 8 && y >= H / 2 && y < H / 2 + 8) obszar = 8;
        else if (y < H / 2) obszar = (x * 8) / W;
        else obszar = 9;
    endfunction
    function [23:0] kolor(input int x, input int y);
        int k;
        logic [7:0] r, g, b, gr;
        begin
            k = obszar(x, y);
            gr = (x * 256) / W;
            if (k == 8) kolor = 24'hFFFFFF;
            else if (k == 9) kolor = {gr, gr, gr};
            else begin
                r = (k == 0 || k == 1 || k == 4 || k == 5) ? 8'd220 : 8'd30;
                g = (k <= 3) ? 8'd220 : 8'd30;
                b = (k == 0 || k == 2 || k == 4 || k == 6) ? 8'd220 : 8'd30;
                kolor = {r, g, b};
            end
        end
    endfunction
    function [7:0] jasn(input [23:0] c);
        logic [16:0] s;
        begin
            s = 17'd77 * c[23:16] + 17'd150 * c[15:8] + 17'd29 * c[7:0] + 17'd128;
            jasn = s[15:8];
        end
    endfunction
    // okno (2r+1)×(2r+1) w jednym obszarze i w obrazie
    function jednolite(input int x, input int y, input int r);
        int i, j, k0;
        begin
            jednolite = (x >= r && x < W - r && y >= r && y < H - r);
            k0 = obszar(x, y);
            for (i = -r; i <= r; i = i + 1)
                for (j = -r; j <= r; j = j + 1)
                    if (jednolite && obszar(x + i, y + j) != k0) jednolite = 0;
        end
    endfunction

    // ---- zapis ramki
    logic [23:0] obraz [0:W*H-1];
    logic        zapis = 1'b0;
    logic        w_ramce = 1'b0;
    logic        gotowa = 1'b0;
    logic        vs_p = 1'b1;
    logic        de_p = 1'b0;
    int    px = 0;
    int    ln = 0;
    int    n_pikseli = 0;
    int    n_ramek = 0;
    always @(posedge clk) begin
        vs_p <= vs;
        de_p <= de;
        if (vs_p && !vs) begin
            n_ramek = n_ramek + 1;
            ln = 0;
            if (w_ramce) begin w_ramce = 1'b0; gotowa = 1'b1; end
            else if (zapis) begin w_ramce = 1'b1; n_pikseli = 0; end
        end else if (de_p && !de)
            ln = ln + 1;
        if (w_ramce && de) begin
            if (px < W && ln < H) obraz[ln * W + px] = rgb;
            n_pikseli = n_pikseli + 1;
        end
        px = de ? px + 1 : 0;
    end

    task ramka_w_trybie(input [2:0] t);
        int n0;
        begin
            tryb = t;
            n0 = n_ramek;
            wait (n_ramek >= n0 + 2);
            gotowa = 1'b0; zapis = 1'b1;
            wait (gotowa);
            zapis = 1'b0;
            if (n_pikseli != W * H) begin $display("FAIL: %0d pikseli w ramce", n_pikseli); errors = errors + 1; end
        end
    endtask

    int x, y, spr, zle, k;
    logic [23:0] ocz;
    logic [7:0]  v;
    logic [31:0] suma_tb;
    initial begin
        repeat (5) @(posedge clk);
        rst = 1'b0;
        // tryb 0: kolor
        ramka_w_trybie(3'd0);
        spr = 0; zle = 0;
        for (y = 0; y < H; y = y + 1) for (x = 0; x < W; x = x + 1)
            if (jednolite(x, y, 1)) begin
                spr = spr + 1;
                if (obraz[y * W + x] != kolor(x, y)) begin
                    if (zle < 3) $display("  (%0d,%0d): %h, oczekiwane %h", x, y, obraz[y * W + x], kolor(x, y));
                    zle = zle + 1;
                end
            end
        $display("tryb 0 (kolor): pikseli z jednolitym oknem 3x3 %0d, niezgodnych %0d", spr, zle);
        if (zle != 0 || spr < 900) errors = errors + 1;
        // tryb 1: szarość i suma jasności
        ramka_w_trybie(3'd1);
        spr = 0; zle = 0; suma_tb = 0;
        for (y = 0; y < H; y = y + 1) for (x = 0; x < W; x = x + 1) begin
            suma_tb = suma_tb + obraz[y * W + x][7:0];
            if (obraz[y * W + x][23:16] != obraz[y * W + x][7:0]) zle = zle + 1;
            if (jednolite(x, y, 1)) begin
                spr = spr + 1;
                if (obraz[y * W + x][7:0] != jasn(kolor(x, y))) zle = zle + 1;
            end
        end
        $display("tryb 1 (szarosc): sprawdzonych %0d, niezgodnych %0d; suma Y ramki %0d (z obrazu %0d)", spr, zle,
                 suma_y, suma_tb);
        if (zle != 0 || suma_y != suma_tb) errors = errors + 1;
        // tryby 2–4: filtry na oknie 5×5 jednolitym
        for (k = 2; k <= 4; k = k + 1) begin
            ramka_w_trybie(k[2:0]);
            spr = 0; zle = 0;
            for (y = 0; y < H; y = y + 1) for (x = 0; x < W; x = x + 1)
                if (jednolite(x, y, 2)) begin
                    spr = spr + 1;
                    if (k == 2) v = jasn(kolor(x, y));                         // rozmycie liniowego = to samo
                    else if (k == 3) v = (obszar(x, y) == 9) ? 8'd32 : 8'd0;    // gradient 4/piksel: |Gx| = 32
                    else v = (obszar(x, y) == 9 && 32 >= PROG) ? 8'd255 : 8'd0;
                    if (obraz[y * W + x] != {v, v, v}) begin
                        if (zle < 3) $display("  tryb %0d (%0d,%0d): %h, oczekiwane %h", k, x, y,
                                              obraz[y * W + x][7:0], v);
                        zle = zle + 1;
                    end
                end
            $display("tryb %0d: sprawdzonych pikseli %0d, niezgodnych %0d", k, spr, zle);
            if (zle != 0 || spr < 600) errors = errors + 1;
        end
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
