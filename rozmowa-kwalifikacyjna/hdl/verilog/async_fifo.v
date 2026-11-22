// Zadanie 8: asynchroniczna kolejka FIFO (Cummings, SNUG 2002). Wskaźniki binarne do adresowania i ich kopie
// w kodzie Graya; do drugiej domeny przechodzi tylko wskaźnik Graya przez dwa przerzutniki — zmienia się
// jeden bit na raz, więc odczytana wartość jest albo stara, albo nowa, nigdy przypadkowa. Pusta: wskaźnik
// odczytu = zsynchronizowany wskaźnik zapisu. Pełna: wskaźnik zapisu = zsynchronizowany wskaźnik odczytu
// z odwróconymi dwoma najstarszymi bitami. Flagi są pesymistyczne (opóźniona wiedza o drugiej stronie), nigdy
// fałszywie optymistyczne. Odczyt rejestrowany (dane takt po rd_en). AW >= 2.
`default_nettype none

module async_fifo #(
    parameter integer W  = 8,
    parameter integer AW = 4
) (
    input  wire         wr_clk,
    input  wire         wr_rst,
    input  wire         wr_en,
    input  wire [W-1:0] wr_data,
    output wire         full,
    input  wire         rd_clk,
    input  wire         rd_rst,
    input  wire         rd_en,
    output reg  [W-1:0] rd_data = {W{1'b0}},
    output wire         empty
);
    reg [W-1:0] mem [0:(1 << AW) - 1];

    // ---------------------------------------------------------------- domena zapisu
    reg  [AW:0] wbin = {(AW + 1){1'b0}};
    reg  [AW:0] wgray = {(AW + 1){1'b0}};
    reg  [AW:0] rgray_w1 = {(AW + 1){1'b0}};
    reg  [AW:0] rgray_w2 = {(AW + 1){1'b0}};
    wire [AW:0] wbin_next = wbin + 1'b1;

    assign full = (wgray == {~rgray_w2[AW:AW-1], rgray_w2[AW-2:0]});

    always @(posedge wr_clk)
        if (wr_en && !full) mem[wbin[AW-1:0]] <= wr_data;

    always @(posedge wr_clk)
        if (wr_rst) begin
            wbin     <= {(AW + 1){1'b0}};
            wgray    <= {(AW + 1){1'b0}};
            rgray_w1 <= {(AW + 1){1'b0}};
            rgray_w2 <= {(AW + 1){1'b0}};
        end else begin
            rgray_w1 <= rgray;
            rgray_w2 <= rgray_w1;
            if (wr_en && !full) begin
                wbin  <= wbin_next;
                wgray <= wbin_next ^ (wbin_next >> 1);
            end
        end

    // ---------------------------------------------------------------- domena odczytu
    reg  [AW:0] rbin = {(AW + 1){1'b0}};
    reg  [AW:0] rgray = {(AW + 1){1'b0}};
    reg  [AW:0] wgray_r1 = {(AW + 1){1'b0}};
    reg  [AW:0] wgray_r2 = {(AW + 1){1'b0}};
    wire [AW:0] rbin_next = rbin + 1'b1;

    assign empty = (rgray == wgray_r2);

    always @(posedge rd_clk)
        if (rd_en && !empty) rd_data <= mem[rbin[AW-1:0]];

    always @(posedge rd_clk)
        if (rd_rst) begin
            rbin     <= {(AW + 1){1'b0}};
            rgray    <= {(AW + 1){1'b0}};
            wgray_r1 <= {(AW + 1){1'b0}};
            wgray_r2 <= {(AW + 1){1'b0}};
        end else begin
            wgray_r1 <= wgray;
            wgray_r2 <= wgray_r1;
            if (rd_en && !empty) begin
                rbin  <= rbin_next;
                rgray <= rbin_next ^ (rbin_next >> 1);
            end
        end
endmodule

`default_nettype wire
