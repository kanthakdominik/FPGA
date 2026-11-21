// Decymator FIR przez M = 4 (26.04): liczy tylko co czwartą próbkę wyjściową filtru N = 32 — jedna mnożarka
// i N taktów na wynik (struktura wielofazowa w czasie: każda próbka wyjściowa to suma czterech podfiltrów
// po 8 współczynników). Próbki w buforze kołowym 64 pozycji (nowe próbki nie nadpisują tych, które są jeszcze
// mnożone). Wymaga ≥ N + 2 taktów między wynikami, czyli przy M = 4 — co najmniej 9 taktów między próbkami we.
`default_nettype none

module pf_dec #(
    parameter integer N = 32
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               we,
    input  wire signed [15:0] x,
    input  wire [16*N-1:0]    wsp,
    output reg  signed [15:0] y,
    output reg                y_wazne
);
    reg signed [15:0] bufor [0:63];
    integer i;
    initial for (i = 0; i < 64; i = i + 1) bufor[i] = 16'sd0;
    /* verilator lint_off WIDTHTRUNC */
    localparam [5:0] OST = N - 1;
    /* verilator lint_on WIDTHTRUNC */
    reg        [5:0]  wp, baza;
    reg        [1:0]  faza;
    reg        [5:0]  k;
    reg               mac, koniec;
    reg signed [39:0] acc;
    /* verilator lint_off WIDTHEXPAND */
    wire signed [15:0] h  = wsp[{k[4:0], 4'd0} +: 16];
    wire signed [15:0] xs = bufor[baza - k];
    wire signed [39:0] zaokr = acc + 40'sd16384;
    /* verilator lint_on WIDTHEXPAND */
    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [24:0] w = zaokr[39:15];
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk) begin
        y_wazne <= 1'b0;
        koniec  <= 1'b0;
        if (rst) begin
            wp <= 6'd0; baza <= 6'd0; faza <= 2'd0; k <= 6'd0; mac <= 1'b0; acc <= 40'sd0; y <= 16'sd0;
        end else begin
            if (we) begin
                bufor[wp] <= x;
                wp   <= wp + 1'b1;
                faza <= faza + 1'b1;
                if (faza == 2'd3) begin                               // co czwarta próbka: start sumy
                    baza <= wp;
                    k    <= 6'd0;
                    acc  <= 40'sd0;
                    mac  <= 1'b1;
                end
            end
            if (mac) begin
                /* verilator lint_off WIDTHEXPAND */
                acc <= acc + h * xs;
                /* verilator lint_on WIDTHEXPAND */
                k   <= k + 1'b1;
                if (k == OST) begin mac <= 1'b0; koniec <= 1'b1; end
            end
            if (koniec) begin
                y       <= (w > 25'sd32767) ? 16'sh7FFF : (w < -25'sd32768) ? 16'sh8000 : w[15:0];
                y_wazne <= 1'b1;
            end
        end
    end
endmodule

`default_nettype wire
