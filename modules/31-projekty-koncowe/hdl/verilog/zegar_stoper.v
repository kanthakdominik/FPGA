// Zegar doby i stoper w kodzie BCD (31.01). Takt setnych sekundy z dzielnika CS_DZIEL (50 MHz / 500 000).
//   zegar:  hh:mm:ss (00:00:00–23:59:59), ustawiany impulsem ustaw (setne zegara zerowane),
//   stoper: mm:ss.cc (00:00.00–99:59.99, potem od zera), start / stop / zeruj (zatrzymuje) / okrążenie.
// Liczniki w BCD: wartości gotowe do wysłania jako znaki ASCII i do wyświetlaczy, bez dzielenia przez 10.
`default_nettype none

module zegar_stoper #(
    parameter integer CS_DZIEL = 500_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        ustaw,
    input  wire [23:0] ustaw_czas,      // BCD: hh, mm, ss
    input  wire        st_start,
    input  wire        st_stop,
    input  wire        st_zeruj,
    input  wire        st_okr,
    output reg  [23:0] czas = 24'h000000,
    output reg  [23:0] stoper = 24'h000000,  // BCD: mm, ss, cc
    output reg  [23:0] okr = 24'h000000,
    output reg         biegnie = 1'b0,
    output wire        tik_cs
);
    localparam integer DW = $clog2(CS_DZIEL);
    /* verilator lint_off WIDTHTRUNC */
    localparam [DW-1:0] OST = CS_DZIEL - 1;
    /* verilator lint_on WIDTHTRUNC */
    reg [DW-1:0] dz = {DW{1'b0}};
    assign tik_cs = (dz == OST);

    // dwie cyfry BCD + 1 z ograniczeniem: {przeniesienie, nowa wartość}
    function [8:0] inc2(input [7:0] v, input [7:0] maks);
        begin
            if (v == maks)          inc2 = {1'b1, 8'h00};
            else if (v[3:0] == 4'd9) inc2 = {1'b0, v[7:4] + 4'd1, 4'd0};
            else                    inc2 = {1'b0, v[7:4], v[3:0] + 4'd1};
        end
    endfunction

    reg  [6:0] cs_z = 7'd0;                       // setne zegara (binarnie)
    wire [8:0] z_s = inc2(czas[7:0], 8'h59);
    wire [8:0] z_m = inc2(czas[15:8], 8'h59);
    /* verilator lint_off UNUSEDSIGNAL */
    wire [8:0] z_h = inc2(czas[23:16], 8'h23);           // przeniesienie z godzin i minut stopera niepotrzebne
    wire [8:0] s_c = inc2(stoper[7:0], 8'h99);
    wire [8:0] s_s = inc2(stoper[15:8], 8'h59);
    wire [8:0] s_m = inc2(stoper[23:16], 8'h99);
    /* verilator lint_on UNUSEDSIGNAL */

    always @(posedge clk) begin
        if (rst) begin
            dz <= {DW{1'b0}}; cs_z <= 7'd0; czas <= 24'h000000;
            stoper <= 24'h000000; okr <= 24'h000000; biegnie <= 1'b0;
        end else begin
            dz <= tik_cs ? {DW{1'b0}} : dz + 1'b1;
            // zegar
            if (ustaw) begin
                czas <= ustaw_czas;
                cs_z <= 7'd0;
            end else if (tik_cs) begin
                if (cs_z == 7'd99) begin
                    cs_z <= 7'd0;
                    czas[7:0] <= z_s[7:0];
                    if (z_s[8]) begin
                        czas[15:8] <= z_m[7:0];
                        if (z_m[8]) czas[23:16] <= z_h[7:0];
                    end
                end else
                    cs_z <= cs_z + 7'd1;
            end
            // stoper
            if (st_zeruj) begin
                stoper <= 24'h000000; okr <= 24'h000000; biegnie <= 1'b0;
            end else begin
                if (st_start) biegnie <= 1'b1;
                if (st_stop)  biegnie <= 1'b0;
                if (st_okr)   okr <= stoper;
                if (biegnie && tik_cs) begin
                    stoper[7:0] <= s_c[7:0];
                    if (s_c[8]) begin
                        stoper[15:8] <= s_s[7:0];
                        if (s_s[8]) stoper[23:16] <= s_m[7:0];
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
