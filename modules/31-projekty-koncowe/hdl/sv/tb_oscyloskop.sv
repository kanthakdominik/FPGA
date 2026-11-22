// Testbench (SystemVerilog) projektu 2 (31.02): dwa zegary (akwizycja 100 MHz, piksel 125 MHz w skali symulacji), pole 128 × 256
// pikseli w małej ramce obrazu. Wejście: trójkąt o okresie 200 próbek (krok 40), potem stała — tryb auto.
// Każda wyświetlona ramka jest analizowana piksel po pikselu i porównywana z modelem: odcinek przebiegu
// w każdej kolumnie, linia poziomu, znacznik wyzwolenia, siatka i ramka pola.
`timescale 1ns / 1ps
`default_nettype none

module tb_oscyloskop;
    localparam int AW = 7, N = 1 << AW, PRZED = 16, X0 = 8, Y0 = 8;
    localparam [11:0] POZIOM = 12'd2048;
    localparam [23:0] C_SIATKA = 24'h404040, C_RAMKA = 24'h808080, C_POZIOM = 24'hFF8000, C_WYZW = 24'h0060FF,
                      C_SLAD = 24'h00FF00;
    logic clk_a = 1'b0;
    logic clk_v = 1'b0;
    always #5 clk_a = ~clk_a;
    always #4 clk_v = ~clk_v;
    logic rst = 1'b1;
    logic we = 1'b0;
    logic [11:0] probka = 12'd0;
    logic stala = 1'b0;
    logic wyzwolony, hs, vs, de;
    logic [23:0] rgb;
    logic [15:0] nr_zrzutu;
    int errors = 0;

    oscyloskop #(.AW(AW), .PRZED(PRZED), .AUTO(512), .X0(X0), .Y0(Y0), .H_AKT(X0 + N + 8), .H_FP(2), .H_SYNC(4),
                 .H_BP(2), .V_AKT(Y0 + 256 + 8), .V_FP(1), .V_SYNC(2), .V_BP(1)) dut (
        .clk_a(clk_a), .rst_a(rst), .we(we), .probka(probka), .poziom(POZIOM), .dziel(8'd1), .tryb_auto(1'b1),
        .wyzwolony(wyzwolony), .clk_v(clk_v), .rst_v(rst), .rgb(rgb), .hs(hs), .vs(vs), .de(de),
        .nr_zrzutu(nr_zrzutu));

    function int trojkat(input int n);
        int k;
        begin
            k = ((n % 200) + 200) % 200;
            trojkat = (k < 100) ? k * 40 : (200 - k) * 40;
        end
    endfunction

    // próbka co drugi takt zegara akwizycji
    int n = 0;
    logic     faza = 1'b0;
    always @(posedge clk_a) begin
        faza <= ~faza;
        we   <= faza;
        if (faza) begin
            probka <= stala ? 12'd1000 : trojkat(n);
            n      <= n + 1;
        end
    end

    // ---- analiza jednej ramki
    logic     analiza = 1'b0;
    logic     w_ramce = 1'b0;
    logic     de_d = 1'b0;
    logic     vs_d = 1'b1;
    logic     gotowa = 1'b0;
    int px = 0;
    int ln = 0;
    int k;
    int smin [0:N-1];
    int smax [0:N-1];
    int scnt [0:N-1];
    int c_poz = 0;
    int c_wyzw = 0;
    int c_siatka = 0;
    int c_ramka = 0;
    int c_inne = 0;
    int c_slad_poza = 0;
    always @(posedge clk_v) begin
        de_d <= de;
        vs_d <= vs;
        if (vs_d && !vs) begin                       // początek impulsu synchronizacji pionowej = koniec ramki
            ln <= 0;
            if (w_ramce) begin w_ramce <= 1'b0; gotowa <= 1'b1; analiza <= 1'b0; end
            else if (analiza) begin
                w_ramce <= 1'b1;
                for (k = 0; k < N; k = k + 1) begin smin[k] = 999; smax[k] = -1; scnt[k] = 0; end
                c_poz = 0; c_wyzw = 0; c_siatka = 0; c_ramka = 0; c_inne = 0; c_slad_poza = 0;
            end
        end else if (de_d && !de)
            ln <= ln + 1;
        px <= de ? px + 1 : 0;
        if (w_ramce && de) begin
            if (px >= X0 && px < X0 + N && ln >= Y0 && ln < Y0 + 256) begin
                case (rgb)
                    C_SLAD: begin
                        if (ln - Y0 < smin[px - X0]) smin[px - X0] = ln - Y0;
                        if (ln - Y0 > smax[px - X0]) smax[px - X0] = ln - Y0;
                        scnt[px - X0] = scnt[px - X0] + 1;
                    end
                    C_POZIOM: c_poz = c_poz + 1;
                    C_WYZW:   c_wyzw = c_wyzw + 1;
                    C_SIATKA: c_siatka = c_siatka + 1;
                    24'h000000: ;
                    default:  c_inne = c_inne + 1;
                endcase
            end else if (rgb == C_RAMKA)
                c_ramka = c_ramka + 1;
            else if (rgb == C_SLAD)
                c_slad_poza = c_slad_poza + 1;
            else if (rgb != 24'h000000)
                c_inne = c_inne + 1;
        end
    end

    task analizuj_ramke;
        begin
            gotowa = 1'b0;
            @(posedge clk_v); analiza = 1'b1;
            wait (gotowa);
        end
    endtask

    // oczekiwane: wiersz próbki w polu i porównanie ramki z modelem
    function int wiersz(input int p);
        wiersz = 255 - p / 16;
    endfunction

    int e_min [0:N-1];
    int e_max [0:N-1];
    task sprawdz(input int stala_wart, input [8*12-1:0] co);
        int i, r, a, b, bl_kol, o_poz, o_wyzw, o_siatka, w_poz;
        begin
            w_poz = 255 - POZIOM / 16;
            for (i = 0; i < N; i = i + 1) begin
                if (stala_wart >= 0) begin a = wiersz(stala_wart); b = a; end
                else begin
                    a = wiersz(trojkat(52 - PRZED + i));
                    b = (i == 0) ? a : wiersz(trojkat(52 - PRZED + i - 1));
                end
                e_min[i] = (a < b) ? a : b;
                e_max[i] = (a < b) ? b : a;
            end
            bl_kol = 0; o_poz = 0; o_wyzw = 0; o_siatka = 0;
            for (i = 0; i < N; i = i + 1) begin
                if (smin[i] != e_min[i] || smax[i] != e_max[i] || scnt[i] != e_max[i] - e_min[i] + 1) begin
                    if (bl_kol < 3) $display("  kolumna %0d: slad %0d..%0d (%0d pikseli), oczekiwane %0d..%0d",
                                             i, smin[i], smax[i], scnt[i], e_min[i], e_max[i]);
                    bl_kol = bl_kol + 1;
                end
                for (r = 0; r < 256; r = r + 1)
                    if (!(r >= e_min[i] && r <= e_max[i])) begin
                        if (r == w_poz) o_poz = o_poz + 1;
                        else if (i == PRZED) o_wyzw = o_wyzw + 1;
                        else if (i % 64 == 0 || r % 32 == 0) o_siatka = o_siatka + 1;
                    end
            end
            $display("%0s: kolumny zgodne %0d/%0d, poziom %0d/%0d, znacznik %0d/%0d, siatka %0d/%0d, ramka %0d/%0d",
                     co, N - bl_kol, N, c_poz, o_poz, c_wyzw, o_wyzw, c_siatka, o_siatka, c_ramka, 2 * N + 4 + 512);
            if (bl_kol != 0 || c_poz != o_poz || c_wyzw != o_wyzw || c_siatka != o_siatka ||
                c_ramka != 2 * N + 4 + 512 || c_inne != 0 || c_slad_poza != 0) begin
                $display("FAIL: %0s: obraz niezgodny z modelem (inne kolory %0d, slad poza polem %0d)", co, c_inne,
                         c_slad_poza);
                errors = errors + 1;
            end
        end
    endtask

    int n0;
    initial begin
        repeat (5) @(posedge clk_a);
        rst = 1'b0;
        wait (nr_zrzutu >= 16'd1);
        if (!wyzwolony) begin $display("FAIL: zrzut trojkata bez wyzwolenia"); errors = errors + 1; end
        analizuj_ramke;
        sprawdz(-1, "trojkat");
        stala = 1'b1;
        n0 = nr_zrzutu;
        wait (nr_zrzutu >= n0 + 2);
        if (wyzwolony) begin $display("FAIL: stala wyzwolila zrzut"); errors = errors + 1; end
        analizuj_ramke;
        sprawdz(1000, "stala (auto)");
        $display("wyswietlonych zrzutow: %0d", nr_zrzutu);
        if (errors == 0) $display("PASS");
        else $display("FAIL: %0d bledow", errors);
        $finish;
    end
endmodule

`default_nettype wire
