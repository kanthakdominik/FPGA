// N kanałów PWM o rozdzielczości W bitów ze wspólnym licznikiem.
// Kanał i ma wypełnienie duty_i / 2**W; duty = 0 — zawsze 0. Wyjścia rejestrowane (bez szpilek).
`default_nettype none

module pwm_multi #(
    parameter integer N = 4,                       // liczba kanałów
    parameter integer W = 8                        // rozdzielczość
) (
    input  wire           clk,
    input  wire           rst,
    input  wire [N*W-1:0] duty,                    // kanał i: duty[i*W +: W]
    output reg  [N-1:0]   pwm
);
    localparam [W-1:0] CNT_MAX = {W{1'b1}};        // localparam: stała wyliczona, nie do zmiany z zewnątrz

    reg [W-1:0] cnt = {W{1'b0}};

    always @(posedge clk) begin
        if (rst) cnt <= {W{1'b0}};
        else     cnt <= (cnt == CNT_MAX) ? {W{1'b0}} : cnt + 1'b1;
    end

    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_ch
            always @(posedge clk) begin
                if (rst) pwm[i] <= 1'b0;
                else     pwm[i] <= (cnt < duty[i*W +: W]);
            end
        end
    endgenerate
endmodule

`default_nettype wire
