// Potok obróbki obrazu (31.05): RAW Bayer -> demozaika -> luminancja Y = (77R + 150G + 29B + 128) / 256
// -> filtr3x3 (24.06) -> wybór trybu:
//   0 — kolor po demozaikowaniu, 1 — szarość (Y), 2 — rozmycie 3×3, 3 — Sobel |Gx| + |Gy|, 4 — krawędzie
//   (Sobel ≥ PROG). Tryby 1–4 idą przez filtr3x3 (1 — tryb przepuszczania), więc mają to samo opóźnienie.
// Tryb zmienia się tylko na początku impulsu vs najpóźniejszej ścieżki — nigdy w środku ramki.
// Statystyka: suma Y wszystkich pikseli aktywnych ramki (do automatycznej ekspozycji), zatrzaskiwana przy vs.
`default_nettype none

module isp #(
    parameter integer L    = 800,
    parameter integer PROG = 96
) (
    input  wire        clk,
    input  wire [2:0]  tryb,
    input  wire        de,
    input  wire        hs,
    input  wire        vs,
    input  wire [7:0]  raw,
    output reg         o_de = 1'b0,
    output reg         o_hs = 1'b1,
    output reg         o_vs = 1'b1,
    output reg  [23:0] rgb = 24'd0,
    output reg  [31:0] suma_y = 32'd0
);
    wire        d_de, d_hs, d_vs;
    wire [23:0] d_rgb;
    demozaika #(.L(L)) u_dem (.clk(clk), .de(de), .hs(hs), .vs(vs), .raw(raw), .o_de(d_de), .o_hs(d_hs),
                              .o_vs(d_vs), .rgb(d_rgb));

    // luminancja
    /* verilator lint_off UNUSEDSIGNAL */
    wire [16:0] y_suma = 17'd77 * d_rgb[23:16] + 17'd150 * d_rgb[15:8] + 17'd29 * d_rgb[7:0] + 17'd128;
    /* verilator lint_on UNUSEDSIGNAL */
    reg  [7:0]  y8 = 8'd0;
    reg         y_de = 1'b0;
    reg         y_hs = 1'b1;
    reg         y_vs = 1'b1;
    always @(posedge clk) begin
        y8 <= y_suma[15:8];
        {y_de, y_hs, y_vs} <= {d_de, d_hs, d_vs};
    end

    reg  [2:0]  tryb_r = 3'd0;
    wire [1:0]  f_tryb = (tryb_r == 3'd2) ? 2'd1 : (tryb_r == 3'd3) ? 2'd2 : (tryb_r == 3'd4) ? 2'd3 : 2'd0;
    wire        f_de, f_hs, f_vs;
    wire [7:0]  f_piks;
    filtr3x3 #(.L(L), .PROG(PROG)) u_filtr (.clk(clk), .tryb(f_tryb), .de(y_de), .hs(y_hs), .vs(y_vs), .piks(y8),
        .o_de(f_de), .o_hs(f_hs), .o_vs(f_vs), .o_piks(f_piks));

    // tryb zatrzaskiwany na początku vs ścieżki filtra (ścieżka koloru jest wtedy też w wygaszaniu)
    reg f_vs_p = 1'b1;
    always @(posedge clk) begin
        f_vs_p <= f_vs;
        if (f_vs_p && !f_vs) tryb_r <= (tryb > 3'd4) ? 3'd0 : tryb;
    end

    always @(posedge clk)
        if (tryb_r == 3'd0) begin
            {o_de, o_hs, o_vs} <= {d_de, d_hs, d_vs};
            rgb <= d_de ? d_rgb : 24'd0;
        end else begin
            {o_de, o_hs, o_vs} <= {f_de, f_hs, f_vs};
            rgb <= f_de ? {f_piks, f_piks, f_piks} : 24'd0;
        end

    // suma jasności ramki
    reg [31:0] akum = 32'd0;
    reg        y_vs_p = 1'b1;
    always @(posedge clk) begin
        y_vs_p <= y_vs;
        if (y_vs_p && !y_vs) begin
            suma_y <= akum;
            akum   <= 32'd0;
        end else if (y_de)
            akum <= akum + {24'd0, y8};
    end
endmodule

`default_nettype wire
