// Biquad w postaci bezpośredniej II transponowanej (26.02), jedna próbka na takt (5 mnożarek):
//   w = Q(b0·x + s1);  s1 <- b1·x - a1·w + s2;  s2 <- b2·x - a2·w;  y = w
// Współczynniki Q2.14 (16 bitów), stany s1, s2 pełnej precyzji (40 bitów, 14 bitów ułamkowych). Q — usunięcie
// 14 bitów ułamkowych wybranym sposobem (parametr ZAOKR) i nasycenie do 16 bitów:
//   0 — obcięcie (floor), 1 — zaokrąglenie do najbliższej, 2 — obcięcie w stronę zera (moduł malejący).
// Kwantyzacja w pętli sprzężenia zwrotnego decyduje o cyklach granicznych przy zerowym wejściu (26.02).
`default_nettype none

module biquad_df2t #(
    parameter integer ZAOKR = 1
) (
    input  wire               clk,
    input  wire               rst,
    input  wire               we,
    input  wire signed [15:0] x,
    input  wire signed [15:0] b0,
    input  wire signed [15:0] b1,
    input  wire signed [15:0] b2,
    input  wire signed [15:0] a1,
    input  wire signed [15:0] a2,
    output reg  signed [15:0] y,
    output reg                y_wazne
);
    /* verilator lint_off WIDTHEXPAND */
    reg  signed [39:0] s1, s2;
    wire signed [39:0] v = b0 * x + s1;
    // kwantyzacja: 14 bitów ułamkowych mniej (młodsze bity v, v_r, v_z odrzucane)
    /* verilator lint_off UNUSEDSIGNAL */
    wire signed [39:0] v_r = v + 40'sd8192;
    wire signed [39:0] v_z = v + 40'sd16383;                     // dla ujemnych: obcięcie w stronę zera
    wire signed [25:0] q = (ZAOKR == 0) ? v[39:14] : (ZAOKR == 1) ? v_r[39:14] : (v[39] ? v_z[39:14] : v[39:14]);
    /* verilator lint_on UNUSEDSIGNAL */
    wire signed [15:0] w = (q > 26'sd32767) ? 16'sh7FFF : (q < -26'sd32768) ? 16'sh8000 : q[15:0];

    always @(posedge clk) begin
        y_wazne <= 1'b0;
        if (rst) begin
            s1 <= 40'sd0; s2 <= 40'sd0; y <= 16'sd0;
        end else if (we) begin
            s1      <= b1 * x - a1 * w + s2;
            s2      <= b2 * x - a2 * w;
            y       <= w;
            y_wazne <= 1'b1;
        end
    end
    /* verilator lint_on WIDTHEXPAND */
endmodule

`default_nettype wire
