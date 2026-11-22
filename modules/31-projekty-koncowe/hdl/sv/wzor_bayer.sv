// Źródło obrazu RAW z mozaiką Bayera RGGB (31.05) — zamiast kamery: scena liczona z pozycji piksela,
// z której zostaje tylko składowa danego miejsca mozaiki (wiersz parzysty: R G R G, nieparzysty: G B G B),
// tak jak w czujniku. Scena: górna połowa — 8 pasów kolorów, dolna — gradient szarości 256·x/W, kwadrat
// (bok W/8) przesuwany co ramkę, gdy ruch = 1. Wyjście rejestrowane, sygnały synchronizacji wyrównane.
`default_nettype none

module wzor_bayer #(
    parameter integer W = 640,
    parameter integer H = 480
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        ruch,
    input  logic        de,
    input  logic        hs,
    input  logic        vs,
    input  logic [11:0] x,
    input  logic [11:0] y,
    input  logic        nowa_ramka,
    output logic         o_de = 1'b0,
    output logic         o_hs = 1'b1,
    output logic         o_vs = 1'b1,
    output logic  [7:0]  raw = 8'd0
);
    localparam integer BOK = W / 8;
    /* verilator lint_off WIDTHTRUNC */
    localparam [11:0] W2 = W - BOK, H2 = H / 2 - BOK;
    /* verilator lint_on WIDTHTRUNC */
    logic [11:0] kx = 12'd0;
    logic [11:0] ky = 12'd0;
    always_ff @(posedge clk)
        if (rst) begin kx <= 12'd0; ky <= 12'd0; end
        else if (nowa_ramka && ruch) begin
            kx <= (kx >= W2) ? 12'd0 : kx + 12'd2;
            ky <= (ky >= H2) ? 12'd0 : ky + 12'd1;
        end

    // pasy: biały, żółty, cyjan, zielony, magenta, czerwony, niebieski, czarny (poziomy 220/30)
    /* verilator lint_off WIDTHTRUNC */
    logic [2:0]  pas;
    assign pas = (x * 8) / W;
    logic [7:0]  grad;
    assign grad = (x * 256) / W;
    /* verilator lint_on WIDTHTRUNC */
    logic        r_on;
    assign r_on = (pas == 3'd0 || pas == 3'd1 || pas == 3'd4 || pas == 3'd5);
    logic        g_on;
    assign g_on = (pas <= 3'd3);
    logic        b_on;
    assign b_on = (pas == 3'd0 || pas == 3'd2 || pas == 3'd4 || pas == 3'd6);
    /* verilator lint_off WIDTHEXPAND */
    logic        kwadrat;
    assign kwadrat = (x >= kx && x < kx + BOK && y >= ky + H / 2 && y < ky + H / 2 + BOK);
    logic  [7:0]  r, g, b;
    always @* begin
        if (kwadrat) begin
            r = 8'd255; g = 8'd255; b = 8'd255;
        end else if (y < H / 2) begin
            r = r_on ? 8'd220 : 8'd30; g = g_on ? 8'd220 : 8'd30; b = b_on ? 8'd220 : 8'd30;
        end else begin
            r = grad; g = grad; b = grad;
        end
    end
    /* verilator lint_on WIDTHEXPAND */

    always_ff @(posedge clk) begin
        o_de <= de; o_hs <= hs; o_vs <= vs;
        case ({y[0], x[0]})
            2'b00:   raw <= r;
            2'b11:   raw <= b;
            default: raw <= g;
        endcase
    end
endmodule

`default_nettype wire
