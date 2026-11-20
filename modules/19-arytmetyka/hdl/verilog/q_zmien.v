// Zmiana formatu liczby stałoprzecinkowej ze znakiem (19.01): z Q o WI bitach (FI ułamkowych)
// na Q o WO bitach (FO ułamkowych). Układ kombinacyjny.
//   ZAOKR: 0 — obcięcie (w dół, do -nieskończoności), 1 — połówka w górę (round half up),
//          2 — zbieżne (połówka do parzystej, round half to even).
//   NASYC: 1 — nasycenie do najbliższej wartości zakresu, 0 — zawijanie (najmłodsze bity).
// przepel = 1, gdy wynik nie mieści się w zakresie wyjścia (w obu trybach).
`default_nettype none

module q_zmien #(
    parameter WI    = 16,
    parameter FI    = 8,
    parameter WO    = 8,
    parameter FO    = 4,
    parameter ZAOKR = 2,
    parameter NASYC = 1
) (
    input  wire [WI-1:0] din,
    output wire [WO-1:0] dout,
    output wire          przepel
);
    localparam D  = FI - FO;                         // > 0: ubywa bitów ułamkowych (zaokrąglanie)
    localparam DL = (D < 0) ? -D : 0;                // przesunięcie w lewo, gdy przybywa bitów ułamkowych
    localparam WT = WI + DL + 1;                     // szerokość pośrednia: +1 bit na przeniesienie
    localparam WR = (WT > WO) ? WT : WO;             // szerokość porównania zakresu

    wire signed [WT-1:0] t;                          // wynik po zaokrągleniu, przed ograniczeniem zakresu

    generate
        if (D > 0) begin : g_zaokr
            wire signed [WT-1:0] x    = {{(WT-WI){din[WI-1]}}, din};
            wire signed [WT-1:0] podl = x >>> D;     // podłoga (obcięcie w dół)
            wire                 w_gore;
            if (ZAOKR == 0) begin : g_obc
                assign w_gore = 1'b0;
            end else if (ZAOKR == 1) begin : g_pol
                assign w_gore = din[D-1];            // reszta >= 1/2 LSB wyjścia
            end else if (D == 1) begin : g_zb1
                assign w_gore = din[0] & podl[0];    // dokładnie połowa: w górę tylko do parzystej
            end else begin : g_zb
                assign w_gore = din[D-1] & ((|din[D-2:0]) | podl[0]);
            end
            assign t = podl + {{(WT-1){1'b0}}, w_gore};
        end else begin : g_bez
            wire signed [WT-1:0] x = {{(WT-WI){din[WI-1]}}, din};
            assign t = x <<< DL;                     // D <= 0: dokładnie, bez zaokrąglania
        end
    endgenerate

    // zakres: wynik mieści się w WO bitach, gdy bity od WO-1 w górę są kopiami bitu znaku
    wire signed [WR-1:0] tr;
    generate
        if (WR > WT) begin : g_rozsz
            assign tr = {{(WR-WT){t[WT-1]}}, t};
        end else begin : g_rowne
            assign tr = t;
        end
    endgenerate
    wire [WR-WO:0]       gora = tr[WR-1:WO-1];
    assign przepel = !((&gora) | (~|gora));

    generate
        if (NASYC != 0) begin : g_nasyc
            assign dout = !przepel     ? tr[WO-1:0] :
                          tr[WR-1]     ? {1'b1, {(WO-1){1'b0}}} :     // najmniejsza wartość
                                         {1'b0, {(WO-1){1'b1}}};      // największa wartość
        end else begin : g_zawin
            assign dout = tr[WO-1:0];
        end
    endgenerate
endmodule

`default_nettype wire
