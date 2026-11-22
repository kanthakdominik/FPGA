// Filtr 3×3 na strumieniu wideo (24.06). Dwie linie opóźniające po L próbek (L = pełna długość linii z
// wygaszaniem, H_TOT) w pamięci RAM dają trzy kolejne wiersze; po dwa rejestry w każdym — okno 3×3.
// Piksele wygaszania wchodzą jako 0, więc brzegi obrazu są uzupełniane zerami bez dodatkowej logiki
// (wymaga ≥ 1 piksela wygaszania poziomego i ≥ 1 linii pionowego). Sygnały de/hs/vs płyną przez te same
// linie opóźniające co piksele — wyjście jest wyrównane do środka okna. Opóźnienie: L + 4 takty (rejestr wejściowy, L, dwa rejestry okna, rejestr wyniku).
// tryb: 0 — bez zmian, 1 — rozmycie [1 2 1; 2 4 2; 1 2 1]/16 z zaokrągleniem, 2 — Sobel |Gx| + |Gy|
// (nasycenie 255), 3 — krawędzie: Sobel ≥ PROG -> 255, inaczej 0.
`default_nettype none

module filtr3x3 #(
    parameter integer L    = 800,
    parameter integer PROG = 128
) (
    input  logic       clk,
    input  logic [1:0] tryb,
    input  logic       de,
    input  logic       hs,
    input  logic       vs,
    input  logic [7:0] piks,
    output logic        o_de,
    output logic        o_hs,
    output logic        o_vs,
    output logic  [7:0] o_piks
);
    localparam integer AW = $clog2(L);
    /* verilator lint_off WIDTHTRUNC */
    localparam [AW-1:0] OST = L - 1;
    localparam [11:0]   PR  = PROG;
    /* verilator lint_on WIDTHTRUNC */

    // wiersz 0 (najnowszy): wejście zarejestrowane, piksel wygaszania = 0
    logic  [10:0] w0 = 11'd0;                       // {de, hs, vs, piksel}
    always_ff @(posedge clk) w0 <= {de, hs, vs, de ? piks : 8'd0};

    // linie opóźniające: zapis pod a, odczyt spod a + 1 -> opóźnienie dokładnie L
    logic  [10:0]   lin1 [0:L-1];
    logic  [7:0]    lin2 [0:L-1];
    logic  [AW-1:0] a = {AW{1'b0}}, an = {AW{1'b0}};
    logic  [10:0]   w1 = 11'd0;
    logic  [7:0]    w2 = 8'd0;
    integer i;
    initial for (i = 0; i < L; i = i + 1) begin lin1[i] = 11'd0; lin2[i] = 8'd0; end
    always_ff @(posedge clk) begin
        a  <= an;
        an <= (an == OST) ? {AW{1'b0}} : an + 1'b1;
        lin1[a] <= w0;
        lin2[a] <= w1[7:0];
        w1 <= lin1[an];
        w2 <= lin2[an];
    end

    // okno: kolumna 0 — najnowsza (prawa), 2 — najstarsza (lewa); wiersz 0 — dolny, 2 — górny
    logic [7:0]  p00 = 0, p01 = 0, p02 = 0, p10 = 0, p11 = 0, p12 = 0, p20 = 0, p21 = 0, p22 = 0;
    logic [2:0]  s1 = 3'd0, s2 = 3'd0;               // sygnały środkowego wiersza: kolumna 1
    always_ff @(posedge clk) begin
        p00 <= w0[7:0]; p01 <= p00; p02 <= p01;
        p10 <= w1[7:0]; p11 <= p10; p12 <= p11;
        p20 <= w2; p21 <= p20; p22 <= p21;
        s1  <= w1[10:8];
        s2  <= s1;
    end

    // obliczenia (kombinacyjnie z okna), wynik w rejestrze wyjściowym
    /* verilator lint_off UNUSEDSIGNAL */          // roz[3:0] — część ułamkowa po dzieleniu przez 16
    logic [11:0] roz;
    assign roz = {4'd0, p00} + {4'd0, p02} + {4'd0, p20} + {4'd0, p22}
                    + {3'd0, p01, 1'b0} + {3'd0, p10, 1'b0} + {3'd0, p12, 1'b0} + {3'd0, p21, 1'b0}
                    + {2'd0, p11, 2'b00} + 12'd8;
    /* verilator lint_on UNUSEDSIGNAL */
    logic signed [11:0] gx;
    assign gx = $signed({4'd0, p00} + {3'd0, p10, 1'b0} + {4'd0, p20})
                          - $signed({4'd0, p02} + {3'd0, p12, 1'b0} + {4'd0, p22});
    logic signed [11:0] gy;
    assign gy = $signed({4'd0, p00} + {3'd0, p01, 1'b0} + {4'd0, p02})
                          - $signed({4'd0, p20} + {3'd0, p21, 1'b0} + {4'd0, p22});
    logic [11:0] ax;
    assign ax = gx[11] ? -gx : gx;
    logic [11:0] ay;
    assign ay = gy[11] ? -gy : gy;
    logic [11:0] sob;
    assign sob = ax + ay;
    logic [7:0]  sob8;
    assign sob8 = (sob > 12'd255) ? 8'd255 : sob[7:0];

    always_ff @(posedge clk) begin
        {o_de, o_hs, o_vs} <= s2;
        case (tryb)
            2'd0:    o_piks <= p11;
            2'd1:    o_piks <= roz[11:4];
            2'd2:    o_piks <= sob8;
            default: o_piks <= (sob >= PR) ? 8'd255 : 8'd0;
        endcase
    end
endmodule

`default_nettype wire
