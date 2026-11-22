// Filtr FIR w strukturze transponowanej (26.01): y[n] = h0·x[n] + z1, z_k = h_k·x[n] + z_{k+1}. Każde mnożenie
// ma swój rejestr sumy — długa ścieżka to tylko jedno mnożenie i jedno dodawanie, niezależnie od N.
// Współczynniki Q1.15 na wejściu wsp (h_i w bitach 16i+15..16i), próbki 16 bitów, wynik zaokrąglony
// (+2^14, przesunięcie o 15) i nasycony do 16 bitów. Jedna próbka na takt (we), wynik takt później (y_wazne).
`default_nettype none

module fir_transp #(
    parameter integer N = 31
) (
    input  logic               clk,
    input  logic               rst,
    input  logic               we,
    input  logic signed [15:0] x,
    input  logic [16*N-1:0]    wsp,
    output logic  signed [15:0] y,
    output logic                y_wazne
);
    logic signed [39:0] z [1:N-1];                // rejestry sum częściowych
    integer i;

    logic signed [15:0] h0;
    assign h0 = wsp[15:0];
    logic signed [39:0] pelny;
    assign pelny = h0 * x + z[1];
    /* verilator lint_off UNUSEDSIGNAL */                // młodsze 15 bitów — część ułamkowa
    logic signed [39:0] zaokr;
    assign zaokr = pelny + 40'sd16384;
    logic signed [24:0] w;
    assign w = zaokr[39:15];
    /* verilator lint_on UNUSEDSIGNAL */

    always_ff @(posedge clk) begin
        y_wazne <= 1'b0;
        if (rst) begin
            for (i = 1; i < N; i = i + 1) z[i] <= 40'sd0;
            y <= 16'sd0;
        end else if (we) begin
            for (i = 1; i < N - 1; i = i + 1) z[i] <= $signed(wsp[16*i +: 16]) * x + z[i+1];
            z[N-1] <= $signed(wsp[16*(N-1) +: 16]) * x;
            y       <= (w > 25'sd32767) ? 16'sh7FFF : (w < -25'sd32768) ? 16'sh8000 : w[15:0];
            y_wazne <= 1'b1;
        end
    end
endmodule

`default_nettype wire
