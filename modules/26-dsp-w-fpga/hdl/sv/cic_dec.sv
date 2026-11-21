// Decymator CIC (26.04): N = 3 integratory przy częstotliwości wejściowej, decymacja przez R, 3 sekcje grzebieniowe
// (opóźnienie M = 1) przy wyjściowej. Wzmocnienie (R·M)^N = 512 dla R = 8 -> rejestry 16 + 9 = 25 bitów;
// przepełnienia integratorów są nieszkodliwe (arytmetyka modulo 2^25, grzebienie je znoszą). Wynik: 9 bitów
// w prawo (podział przez wzmocnienie, obcięcie). Bez mnożarek.
`default_nettype none

module cic_dec #(
    parameter integer R = 8
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               we,
    input  logic signed [15:0] x,
    output logic  signed [15:0] y,
    output logic                y_wazne
);
    localparam integer CW = $clog2(R) > 0 ? $clog2(R) : 1;
    /* verilator lint_off WIDTHTRUNC */
    localparam [CW-1:0] OST = R - 1;
    /* verilator lint_on WIDTHTRUNC */
    logic  signed [24:0] i1, i2, i3, d1, d2, d3;
    logic  [CW-1:0]      n;
    logic signed [24:0] i1n;
    assign i1n = i1 + {{9{x[15]}}, x};
    logic signed [24:0] i2n;
    assign i2n = i2 + i1n;
    logic signed [24:0] i3n;
    assign i3n = i3 + i2n;
    logic signed [24:0] c1;
    assign c1 = i3n - d1;
    logic signed [24:0] c2;
    assign c2 = c1 - d2;
    /* verilator lint_off UNUSEDSIGNAL */
    logic signed [24:0] c3;
    assign c3 = c2 - d3;                 // c3[8:0] odrzucone (dzielenie przez 512)
    /* verilator lint_on UNUSEDSIGNAL */

    always_ff @(posedge clk) begin
        y_wazne <= 1'b0;
        if (rst) begin
            i1 <= 25'sd0; i2 <= 25'sd0; i3 <= 25'sd0; d1 <= 25'sd0; d2 <= 25'sd0; d3 <= 25'sd0;
            n <= {CW{1'b0}}; y <= 16'sd0;
        end else if (we) begin
            i1 <= i1n; i2 <= i2n; i3 <= i3n;
            n  <= (n == OST) ? {CW{1'b0}} : n + 1'b1;
            if (n == OST) begin                                   // co R-ta próbka: sekcje grzebieniowe
                d1 <= i3n; d2 <= c1; d3 <= c2;
                y       <= c3[24:9];
                y_wazne <= 1'b1;
            end
        end
    end
endmodule

`default_nettype wire
