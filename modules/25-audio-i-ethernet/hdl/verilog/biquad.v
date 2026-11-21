// Filtr IIR drugiego rzędu (biquad, 25.02), postać bezpośrednia I:
//   y[n] = b0·x[n] + b1·x[n-1] + b2·x[n-2] - a1·y[n-1] - a2·y[n-2]
// Współczynniki Q2.16 (18 bitów ze znakiem, zakres [-2, 2)), próbki 24-bitowe ze znakiem, akumulator 48-bitowy.
// Jedna mnożarka używana pięć razy na próbkę (5 taktów + 1 na zaokrąglenie i nasycenie) — przy fs = 48 kHz
// zegar ma setki taktów na próbkę. Wynik zaokrąglony (+2^15, przesunięcie o 16) i nasycony do 24 bitów.
`default_nettype none

module biquad (
    input  wire               clk,
    input  wire               rst,
    input  wire               we,               // impuls: nowa próbka x
    input  wire signed [23:0] x,
    input  wire signed [17:0] b0,
    input  wire signed [17:0] b1,
    input  wire signed [17:0] b2,
    input  wire signed [17:0] a1,
    input  wire signed [17:0] a2,
    output reg  signed [23:0] y,
    output reg                y_wazne
);
    reg signed [23:0] x0, x1, x2, y1, y2;
    reg signed [47:0] acc;
    reg        [2:0]  k;                        // 0..4 — kolejne iloczyny, 5 — wynik, 7 — bezczynność

    // mnożarka: współczynnik i próbka wybrane krokiem k (dla a1, a2 — iloczyn odejmowany)
    reg signed [17:0] c;
    reg signed [23:0] s;
    always @(*) begin
        case (k)
            3'd0:    begin c = b0; s = x0; end
            3'd1:    begin c = b1; s = x1; end
            3'd2:    begin c = b2; s = x2; end
            3'd3:    begin c = a1; s = y1; end
            default: begin c = a2; s = y2; end
        endcase
    end
    /* verilator lint_off WIDTHEXPAND */
    wire signed [41:0] il  = c * s;
    /* verilator lint_on WIDTHEXPAND */
    wire signed [47:0] il48 = {{6{il[41]}}, il};
    /* verilator lint_off UNUSEDSIGNAL */      // zaokr[15:0] — część ułamkowa
    wire signed [47:0] zaokr = acc + 48'sd32768;
    /* verilator lint_on UNUSEDSIGNAL */
    wire signed [31:0] wynik = zaokr[47:16];
    wire signed [23:0] nasyc = (wynik > 32'sd8388607)  ? 24'sh7FFFFF :
                               (wynik < -32'sd8388608) ? 24'sh800000 : wynik[23:0];

    always @(posedge clk) begin
        y_wazne <= 1'b0;
        if (rst) begin
            x0 <= 24'sd0; x1 <= 24'sd0; x2 <= 24'sd0; y1 <= 24'sd0; y2 <= 24'sd0;
            acc <= 48'sd0; k <= 3'd7; y <= 24'sd0;
        end else if (k == 3'd7) begin
            if (we) begin
                x0  <= x;
                acc <= 48'sd0;
                k   <= 3'd0;
            end
        end else if (k == 3'd5) begin
            y       <= nasyc;
            y_wazne <= 1'b1;
            x2 <= x1; x1 <= x0;
            y2 <= y1; y1 <= nasyc;
            k  <= 3'd7;
        end else begin
            acc <= (k >= 3'd3) ? acc - il48 : acc + il48;
            k   <= k + 1'b1;
        end
    end
endmodule

`default_nettype wire
