// Projekt 5 (31.05): takt_wideo -> wzor_bayer (zamiast kamery: RAW RGGB) -> isp -> wyjście RGB z
// synchronizacją, gotowe dla nadajnika HDMI. Z kamerą MIPI CSI-2 (24.05) wejściem isp są piksele RAW8/RAW10
// z odbiornika CSI-2 po buforze linii — potok obróbki jest ten sam.
`default_nettype none

module projekt_obraz #(
    parameter integer H_AKT = 640, parameter integer H_FP = 16, parameter integer H_SYNC = 96,
    parameter integer H_BP  = 48,
    parameter integer V_AKT = 480, parameter integer V_FP = 10, parameter integer V_SYNC = 2,
    parameter integer V_BP  = 33,
    parameter integer PROG  = 96
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  tryb,
    input  wire        ruch,
    output wire        de,
    output wire        hs,
    output wire        vs,
    output wire [23:0] rgb,
    output wire [31:0] suma_y
);
    wire        t_hs, t_vs, t_de, t_nowa, b_de, b_hs, b_vs;
    wire [11:0] tx, ty;
    wire [7:0]  raw;
    takt_wideo #(.H_AKT(H_AKT), .H_FP(H_FP), .H_SYNC(H_SYNC), .H_BP(H_BP), .V_AKT(V_AKT), .V_FP(V_FP),
                 .V_SYNC(V_SYNC), .V_BP(V_BP)) u_takt (.clk(clk), .rst(rst), .hs(t_hs), .vs(t_vs), .de(t_de),
                 .x(tx), .y(ty), .nowa_ramka(t_nowa));
    wzor_bayer #(.W(H_AKT), .H(V_AKT)) u_wzor (.clk(clk), .rst(rst), .ruch(ruch), .de(t_de), .hs(t_hs), .vs(t_vs),
        .x(tx), .y(ty), .nowa_ramka(t_nowa), .o_de(b_de), .o_hs(b_hs), .o_vs(b_vs), .raw(raw));
    isp #(.L(H_AKT + H_FP + H_SYNC + H_BP), .PROG(PROG)) u_isp (.clk(clk), .tryb(tryb), .de(b_de), .hs(b_hs),
        .vs(b_vs), .raw(raw), .o_de(de), .o_hs(hs), .o_vs(vs), .rgb(rgb), .suma_y(suma_y));
endmodule

`default_nettype wire
