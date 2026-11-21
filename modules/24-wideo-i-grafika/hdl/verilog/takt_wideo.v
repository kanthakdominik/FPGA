// Generator taktowania wideo (24.01): liczniki poziomy i pionowy, synchronizacja, obszar aktywny.
// Kolejność w linii i w ramce: obszar aktywny, przedsionek (front porch), impuls synchronizacji, tylny próg
// (back porch). Wyjścia są rejestrowane i wzajemnie wyrównane (x, y, de, hs, vs dotyczą tego samego piksela).
// Polaryzacja: POL = 1 — impuls dodatni, 0 — ujemny. Domyślnie 640×480 przy 60 Hz (zegar 25,175 MHz).
`default_nettype none

module takt_wideo #(
    parameter integer H_AKT  = 640,
    parameter integer H_FP   = 16,
    parameter integer H_SYNC = 96,
    parameter integer H_BP   = 48,
    parameter integer V_AKT  = 480,
    parameter integer V_FP   = 10,
    parameter integer V_SYNC = 2,
    parameter integer V_BP   = 33,
    parameter         H_POL  = 1'b0,
    parameter         V_POL  = 1'b0
) (
    input  wire        clk,
    input  wire        rst,
    output reg         hs,
    output reg         vs,
    output reg         de,
    output reg  [11:0] x,
    output reg  [11:0] y,
    output reg         nowa_ramka                  // pierwszy piksel aktywny ramki
);
    /* verilator lint_off WIDTHTRUNC */
    localparam [11:0] H_TOT = H_AKT + H_FP + H_SYNC + H_BP;
    localparam [11:0] V_TOT = V_AKT + V_FP + V_SYNC + V_BP;
    localparam [11:0] HA    = H_AKT;
    localparam [11:0] HS0   = H_AKT + H_FP;
    localparam [11:0] HS1   = H_AKT + H_FP + H_SYNC;
    localparam [11:0] VA    = V_AKT;
    localparam [11:0] VS0   = V_AKT + V_FP;
    localparam [11:0] VS1   = V_AKT + V_FP + V_SYNC;
    /* verilator lint_on WIDTHTRUNC */

    reg [11:0] hc, vc;

    always @(posedge clk) begin
        if (rst) begin
            hc         <= 12'd0;
            vc         <= 12'd0;
            hs         <= ~H_POL;
            vs         <= ~V_POL;
            de         <= 1'b0;
            x          <= 12'd0;
            y          <= 12'd0;
            nowa_ramka <= 1'b0;
        end else begin
            if (hc == H_TOT - 1'b1) begin
                hc <= 12'd0;
                vc <= (vc == V_TOT - 1'b1) ? 12'd0 : vc + 1'b1;
            end else begin
                hc <= hc + 1'b1;
            end
            // wyjścia dla piksela (hc, vc)
            de         <= (hc < HA) && (vc < VA);
            hs         <= ((hc >= HS0) && (hc < HS1)) ? H_POL : ~H_POL;
            vs         <= ((vc >= VS0) && (vc < VS1)) ? V_POL : ~V_POL;
            x          <= hc;
            y          <= vc;
            nowa_ramka <= (hc == 12'd0) && (vc == 12'd0);
        end
    end
endmodule

`default_nettype wire
