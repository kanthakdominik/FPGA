// Zadanie 12: filtr FIR 8 współczynników w strukturze transponowanej. Każde mnożenie trafia od razu do sumatora
// z rejestrem, więc ścieżka krytyczna to jedno mnożenie i jedno dodawanie niezależnie od liczby współczynników
// (w strukturze bezpośredniej — mnożenie i drzewo sumatorów). Opóźnienie 1 takt. Współczynniki symetryczne
// (filtr dolnoprzepustowy, faza liniowa), suma 256 — wzmocnienie stałej składowej 256.
//   y[n] = sum h[k] * x[n-k],  h = 2, -10, 40, 96, 96, 40, -10, 2
`default_nettype none

module fir_transposed (
    input  wire               clk,
    input  wire               rst,
    input  wire               en,       // nowa próbka
    input  wire signed [11:0] x,
    output reg  signed [23:0] y = 24'sd0
);
    function signed [23:0] h(input integer k);
        case (k)
            0, 7:    h = 24'sd2;
            1, 6:    h = -24'sd10;
            2, 5:    h = 24'sd40;
            default: h = 24'sd96;
        endcase
    endfunction

    wire signed [23:0] xe = {{12{x[11]}}, x};
    reg  [24*7-1:0]    s = {(24 * 7){1'b0}};     // sumy częściowe s[k] = s[24k +: 24]
    integer            k;

    always @(posedge clk)
        if (rst) begin
            y <= 24'sd0;
            s <= {(24 * 7){1'b0}};
        end else if (en) begin
            y <= xe * h(0) + $signed(s[23:0]);
            for (k = 0; k < 6; k = k + 1)
                s[24 * k +: 24] <= xe * h(k + 1) + $signed(s[24 * (k + 1) +: 24]);
            s[24 * 6 +: 24] <= xe * h(7);
        end
endmodule

`default_nettype wire
