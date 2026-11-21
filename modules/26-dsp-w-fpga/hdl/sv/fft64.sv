// FFT 64 punktów, radix-2 z podziałem w czasie (26.05), jeden motyl na takt, obliczenia w miejscu.
// Wczytanie 64 próbek zespolonych (we, xr, xi) pod adresy z odwróconą kolejnością bitów, 6 etapów po 32 motyle
// (192 takty), wypisanie 64 wyników w kolejności naturalnej (wy_wazne, yr, yi). Liczby 16-bitowe; współczynniki
// obrotu Q1.15 z tw_tab. Motyl: t = W·b (zaokrąglenie, przesunięcie o 15), a' = (a + t)/2, b' = (a - t)/2 —
// skalowanie o 1/2 na etap, razem 1/64 (wynik = DFT/64), bez przepełnień dla |x| ≤ 32767.
`default_nettype none

module fft64 (
    input  logic               clk,
    input  logic               rst,
    input  logic               we,
    input  logic signed [15:0] xr,
    input  logic signed [15:0] xi,
    output logic               gotowy,           // przyjmuje próbki
    output logic  signed [15:0] yr,
    output logic  signed [15:0] yi,
    output logic                wy_wazne
);
    logic signed [15:0] mr [0:63];
    logic signed [15:0] mi [0:63];
    localparam [1:0] S_WCZYT = 2'd0, S_LICZ = 2'd1, S_WYJ = 2'd2;
    logic  [1:0] stan;
    logic  [5:0] n;                               // licznik próbek albo motyli (5 bitów) w etapie
    logic  [2:0] etap;                            // 1..6
    assign gotowy = (stan == S_WCZYT);

    function [5:0] odwr(input [5:0] a);
        odwr = {a[0], a[1], a[2], a[3], a[4], a[5]};
    endfunction

    // indeksy motyla b (0..31) w etapie s: pol = 2^(s-1), górny = (b / pol)·2·pol + b mod pol, dolny = górny + pol
    logic [5:0] gora, dol;
    logic [4:0] kw;
    always_comb begin
        case (etap)
            3'd1:    begin gora = {n[4:0], 1'b0};             kw = 5'd0;              end
            3'd2:    begin gora = {n[4:1], 1'b0, n[0]};       kw = {n[0], 4'd0};      end
            3'd3:    begin gora = {n[4:2], 1'b0, n[1:0]};     kw = {n[1:0], 3'd0};    end
            3'd4:    begin gora = {n[4:3], 1'b0, n[2:0]};     kw = {n[2:0], 2'd0};    end
            3'd5:    begin gora = {n[4], 1'b0, n[3:0]};       kw = {n[3:0], 1'b0};    end
            default: begin gora = {1'b0, n[4:0]};             kw = n[4:0];            end
        endcase
        dol = gora | (6'd1 << (etap - 3'd1));
    end
    logic signed [15:0] wr, wi;
    tw_tab u_tw (.k(kw), .wr(wr), .wi(wi));

    logic signed [15:0] ar;
    assign ar = mr[gora];
    logic signed [15:0] ai;
    assign ai = mi[gora];
    logic signed [15:0] br;
    assign br = mr[dol];
    logic signed [15:0] bi;
    assign bi = mi[dol];
    /* verilator lint_off WIDTHEXPAND */
    /* verilator lint_off UNUSEDSIGNAL */
    logic signed [32:0] pr;
    assign pr = wr * br - wi * bi + 33'sd16384;
    logic signed [32:0] pq;
    assign pq = wr * bi + wi * br + 33'sd16384;
    /* verilator lint_on WIDTHEXPAND */
    logic signed [17:0] tr;
    assign tr = pr[32:15];
    logic signed [17:0] ti;
    assign ti = pq[32:15];
    logic signed [17:0] s1r;
    assign s1r = ar + tr;
    logic signed [17:0] s1i;
    assign s1i = ai + ti;
    logic signed [17:0] s2r;
    assign s2r = ar - tr;
    logic signed [17:0] s2i;
    assign s2i = ai - ti;
    /* verilator lint_on UNUSEDSIGNAL */

    always_ff @(posedge clk) begin
        wy_wazne <= 1'b0;
        if (rst) begin
            stan <= S_WCZYT; n <= 6'd0; etap <= 3'd1; yr <= 16'sd0; yi <= 16'sd0;
        end else case (stan)
            S_WCZYT:
                if (we) begin
                    mr[odwr(n)] <= xr;
                    mi[odwr(n)] <= xi;
                    n <= n + 1'b1;
                    if (n == 6'd63) begin stan <= S_LICZ; n <= 6'd0; etap <= 3'd1; end
                end
            S_LICZ: begin
                mr[gora] <= s1r[16:1]; mi[gora] <= s1i[16:1];
                mr[dol]  <= s2r[16:1]; mi[dol]  <= s2i[16:1];
                if (n[4:0] == 5'd31) begin
                    n <= 6'd0;
                    if (etap == 3'd6) stan <= S_WYJ;
                    else etap <= etap + 1'b1;
                end else
                    n <= n + 1'b1;
            end
            default: begin
                yr <= mr[n]; yi <= mi[n]; wy_wazne <= 1'b1;
                n  <= n + 1'b1;
                if (n == 6'd63) begin stan <= S_WCZYT; n <= 6'd0; end
            end
        endcase
    end
endmodule

`default_nettype wire
